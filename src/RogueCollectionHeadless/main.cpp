/**
 * Headless entry point for Rogue Collection.
 *
 * Runs a Rogue game entirely through pipes (no GUI). Intended to be
 * spawned by the Python RogueGame class with --pipe-io, --trogue-fd,
 * and --frogue-fd arguments.
 */

#include <cstdlib>
#include <ctime>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>

#include "args.h"
#include "environment.h"
#include "game_config.h"
#include "pipe_input.h"
#include "pipe_output.h"
#include "run_game.h"

// Virtual destructors required by DisplayInterface and InputInterface.
// Normally defined in each frontend (QML plugin, SDL main, etc.).
DisplayInterface::~DisplayInterface() {}
InputInterface::~InputInterface() {}

int main(int argc, char** argv)
{
    Args args(argc, argv);

    // Ensure pipe_io is set (headless binary always uses pipes).
    args.pipe_io = true;

    Environment env(args);

    // Resolve game version from the positional argument.
    std::string game_name = args.savefile;
    if (game_name.empty()) {
        std::cerr << "Usage: " << argv[0]
                  << " <game-name> --pipe-io --trogue-fd <fd> --frogue-fd <fd>"
                  << std::endl;
        return 1;
    }

    int idx = GetGameIndex(game_name);
    if (idx == -1) {
        std::cerr << "Unknown game: " << game_name << std::endl;
        return 1;
    }

    GameConfig config = GetGameConfig(idx);

    int frogue_fd = args.GetDescriptorFromRogue();
    int trogue_fd = args.GetDescriptorToRogue();

    if (frogue_fd <= 0 || trogue_fd <= 0) {
        std::cerr << "Invalid pipe file descriptors (trogue="
                  << trogue_fd << ", frogue=" << frogue_fd << ")"
                  << std::endl;
        return 1;
    }

    // Set up game environment.
    Environment game_env(args);
    game_env.SetRogomaticValues();

    std::ostringstream ss;
    if (!args.seed.empty()) {
        ss << args.seed;
    } else {
        ss << static_cast<int>(time(nullptr));
    }
    game_env.Set("seed", ss.str());

    if (!game_env.WriteToOs(config.is_unix)) {
        std::cerr << "Couldn't write environment" << std::endl;
        return 1;
    }

    // Create pipe-based display and input (no GUI).
    PipeOutput display(frogue_fd);
    PipeInput input(&env, &game_env, config, trogue_fd);

    int lines = config.screen.y;
    int cols  = config.screen.x;

    RunGame(config.dll_name, &display, &input, &game_env, lines, cols, args);

    return 0;
}
