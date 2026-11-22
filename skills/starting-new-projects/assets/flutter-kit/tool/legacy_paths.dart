/// Code that predates the rules. A new project has none, so the list is
/// empty and every file follows the strict rules. If you adopt old code, add
/// its folder here, give the folder its own analysis_options.yaml, and take
/// it off the list in the pull request that migrates it.
library;

const legacyPaths = <String>[];

bool isLegacy(String path) => legacyPaths.any(path.startsWith);
