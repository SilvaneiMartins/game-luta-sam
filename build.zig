const std = @import("std");

// Chame .Pkg com a pasta raylib-zig é relativo ao projeto build.zig
const raylib = @import("./raylib-zig");

// Embora esta função pareça imperativa, observe que sua função é
// construir declarativamente um gráfico de construção que será executado por um
// executor externo.
pub fn build(b: *std.Build) void {
    // As opções de alvo padrão permitem que a pessoa que executa `zig build` escolha
    // para qual alvo construir. Aqui não substituímos os padrões, o que
    // significa que qualquer alvo é permitido, e o padrão é nativo. Outras opções
    // para restringir o conjunto de alvos suportados estão disponíveis.
    const target = b.standardTargetOptions(.{});

    // As opções de otimização padrão permitem que a pessoa que executa `zig build` selecione
    // entre Debug, ReleaseSafe, ReleaseFast e ReleaseSmall. Aqui não
    // definimos um modo de lançamento preferencial, permitindo que o usuário decida como otimizar.
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "game-luta-sam",
        // Neste caso, o arquivo de origem principal é apenas um caminho, no entanto, em scripts de construção mais
        // complicados, este pode ser um arquivo gerado.
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const system_lib = b.option(bool, "system-raylib", "link to preinstall raylib libraries") orelse false;

    // Isso declara a intenção de que a biblioteca seja instalada no local
    // padrão quando o usuário invoca a etapa "install" (a etapa padrão ao
    // executar `zig build`).
    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "game-luta-sam",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Isso declara a intenção de que o executável seja instalado no
    // local padrão quando o usuário invoca a etapa "install" (a etapa
    // padrão ao executar `zig build`).
    b.installArtifact(exe);

    // Linkar com a biblioteca raylib
    raylib.link(exe, system_lib);
    raylib.addAsPackage("raylib", exe);
    raylib.math.addAsPackage("raylib-math", exe);

    // Isso *cria* uma etapa Run no gráfico de construção, a ser executada quando outra
    // etapa for avaliada que depende dela. A próxima linha abaixo estabelecerá
    // tal dependência.
    const run_cmd = b.addRunArtifact(exe);

    // Ao fazer a etapa de execução depender da etapa de instalação, ela será executada a partir do
    // diretório de instalação em vez de diretamente de dentro do diretório de cache.
    // Isso não é necessário, no entanto, se o aplicativo depender de outros arquivos
    // instalados, isso garante que eles estarão presentes e no local esperado.
    run_cmd.step.dependOn(b.getInstallStep());

    // Isso permite que o usuário passe argumentos para o aplicativo no comando build
    // em si, assim: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // Isso cria uma etapa de construção. Ela ficará visível no menu `zig build --help`,
    // e pode ser selecionada assim: `zig build run`
    // Isso avaliará a etapa `run` em vez do padrão, que é "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Cria uma etapa para teste de unidade. Isso apenas constrói o executável de teste
    // mas não o executa.
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Semelhante à criação da etapa de execução anterior, isso expõe uma etapa de `teste` para
    // o menu `zig build --help`, fornecendo uma maneira para o usuário solicitar
    // a execução dos testes de unidade.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
