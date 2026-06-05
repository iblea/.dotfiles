local M = {}

local root_markers1 = {
  "mvnw",
  "gradlew",
  "settings.gradle",
  "settings.gradle.kts",
  ".git",
}

local root_markers2 = {
  "build.xml",
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
}

local function is_dir(path)
  return path and path ~= "" and vim.fn.isdirectory(path) == 1
end

local function is_file(path)
  return path and path ~= "" and vim.fn.filereadable(path) == 1
end

local function first_dir(paths)
  for _, path in ipairs(paths) do
    local expanded = path and vim.fn.expand(path) or nil

    if is_dir(expanded) then
      return expanded
    end
  end
end

local function first_file(paths)
  for _, path in ipairs(paths) do
    local expanded = path and vim.fn.expand(path) or nil

    if is_file(expanded) then
      return expanded
    end
  end
end

local function java_major(java_home)
  local java = java_home and (java_home .. "/bin/java") or nil

  if vim.fn.executable(java) ~= 1 then
    return nil
  end

  local output = vim.fn.system(vim.fn.shellescape(java) .. " -version 2>&1")
  local version = output:match('version "([^"]+)"')

  if not version then
    return nil
  end

  if version:match("^1%.") then
    return tonumber(version:match("^1%.(%d+)"))
  end

  return tonumber(version:match("^(%d+)"))
end

local function first_java_home(paths, predicate)
  for _, path in ipairs(paths) do
    local expanded = path and vim.fn.expand(path) or nil
    local major = is_dir(expanded) and java_major(expanded) or nil

    if major and predicate(major) then
      return expanded
    end
  end
end

local function mac_java_home(version, predicate)
  if vim.fn.executable("/usr/libexec/java_home") ~= 1 then
    return nil
  end

  local result = vim.fn.systemlist({ "/usr/libexec/java_home", "-v", version })

  if vim.v.shell_error == 0 then
    return first_java_home({ result[1] }, predicate)
  end
end

local function java21_or_later(major)
  return major >= 21
end

local function java8(major)
  return major == 8
end

local function find_java21_home()
  return first_java_home({
    vim.env.JDTLS_JAVA_HOME,
    vim.env.JAVA21_HOME,
    vim.env.JAVA_HOME_21,
    vim.env.JDK21_HOME,
    vim.env.JAVA_HOME,
  }, java21_or_later) or mac_java_home("21", java21_or_later) or first_java_home({
    "/opt/homebrew/opt/openjdk@21",
    "/usr/local/opt/openjdk@21",
  }, java21_or_later)
end

local function find_java8_home()
  return first_java_home({
    vim.env.JDTLS_PROJECT_JAVA_HOME,
    vim.env.JAVA8_HOME,
    vim.env.JAVA_HOME_8,
    vim.env.JDK8_HOME,
    vim.env.JAVA_HOME,
  }, java8) or mac_java_home("1.8", java8) or first_java_home({
    "/Library/Java/JavaVirtualMachines/zulu-8.jdk/Contents/Home",
    "/Library/Java/JavaVirtualMachines/adoptopenjdk-8.jdk/Contents/Home",
    "/Library/Java/JavaVirtualMachines/temurin-8.jdk/Contents/Home",
  }, java8)
end

local function find_lombok_jar()
  local configured = vim.env.JDTLS_LOMBOK_JAR

  if is_file(configured) then
    return configured
  end

  local m2_repository = vim.env.M2_REPO or (vim.fn.expand("~") .. "/.m2/repository")
  local lombok_dir = m2_repository .. "/org/projectlombok/lombok"

  if not is_dir(lombok_dir) then
    return nil
  end

  local jars = vim.fn.glob(lombok_dir .. "/*/lombok-*.jar", false, true)

  table.sort(jars, function(a, b)
    local a_version = a:match("/lombok/([^/]+)/lombok%-") or ""
    local b_version = b:match("/lombok/([^/]+)/lombok%-") or ""
    local a_parts = {}
    local b_parts = {}

    for part in a_version:gmatch("%d+") do
      table.insert(a_parts, tonumber(part))
    end

    for part in b_version:gmatch("%d+") do
      table.insert(b_parts, tonumber(part))
    end

    for idx = 1, math.max(#a_parts, #b_parts) do
      local a_part = a_parts[idx] or 0
      local b_part = b_parts[idx] or 0

      if a_part ~= b_part then
        return a_part > b_part
      end
    end

    return a > b
  end)

  return jars[1]
end

local function java_sources(java_home)
  return first_file({
    java_home and (java_home .. "/src.zip") or nil,
    java_home and (java_home .. "/lib/src.zip") or nil,
  })
end

local function find_root(bufnr)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  return vim.fs.root(fname, root_markers1) or vim.fs.root(fname, root_markers2)
end

local function get_workspace_dir(root_dir)
  local project_name = vim.fn.fnamemodify(root_dir, ":p:t")

  if project_name == "" then
    project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
  end

  return vim.fn.stdpath("cache") .. "/jdtls/workspace/" .. project_name
end

local function get_cmd(root_dir)
  local lombok_jar = find_lombok_jar()
  local jvm_args = vim.env.JDTLS_JVM_ARGS or ""
  local cmd = {
    "jdtls",
    "-data",
    get_workspace_dir(root_dir),
  }

  for arg in jvm_args:gmatch("%S+") do
    table.insert(cmd, "--jvm-arg=" .. arg)
  end

  if lombok_jar and not jvm_args:find("lombok", 1, true) then
    table.insert(cmd, "--jvm-arg=-javaagent:" .. lombok_jar)
  end

  return cmd
end

M.setup = function(on_attach, capabilities)
  local java8_home = find_java8_home()
  local java21_home = find_java21_home()
  local group = vim.api.nvim_create_augroup("JdtlsStart", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "java",
    callback = function(args)
      local name = vim.api.nvim_buf_get_name(args.buf)

      if not name:match("^/") then
        return
      end

      local root_dir = find_root(args.buf)

      if not root_dir then
        vim.notify("jdtls root not found", vim.log.levels.WARN)
        return
      end

      if not java21_home then
        vim.notify(
          "Java 21 runtime not found. Set JDTLS_JAVA_HOME for jdtls.",
          vim.log.levels.WARN
        )
      end

      if not java8_home then
        vim.notify(
          "Java 8 runtime not found. Set JDTLS_PROJECT_JAVA_HOME for JavaSE-1.8 projects.",
          vim.log.levels.WARN
        )
      end

      local cmd_env

      if java21_home then
        cmd_env = {
          JAVA_HOME = java21_home,
          PATH = java21_home .. "/bin:" .. (vim.env.PATH or ""),
        }
      end

      local java_runtime

      if java8_home then
        java_runtime = {
          name = "JavaSE-1.8",
          path = java8_home,
          sources = java_sources(java8_home),
          default = true,
        }
      end

      require("jdtls").start_or_attach({
        name = "jdtls",
        cmd = get_cmd(root_dir),
        cmd_env = cmd_env,
        root_dir = root_dir,
        on_attach = on_attach,
        capabilities = capabilities or {},
        init_options = {
          bundles = {},
        },
        settings = {
          java = {
            jdt = {
              ls = {
                lombokSupport = {
                  enabled = true,
                },
              },
            },
            configuration = {
              runtimes = java_runtime and { java_runtime } or {},
              updateBuildConfiguration = "automatic",
            },
            import = {
              maven = {
                enabled = true,
              },
              gradle = {
                enabled = true,
                java = java8_home and {
                  home = java8_home,
                } or nil,
              },
            },
            project = {
              referencedLibraries = {
                "lib/**/*.jar",
              },
            },
          },
        },
      })
    end,
  })
end

return M
