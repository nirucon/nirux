# Fish completions for NIRUX.
complete -c nirux -f
complete -c nirux -n __fish_use_subcommand -a install -d 'Install NIRU'
complete -c nirux -n __fish_use_subcommand -a update -d 'Update NIRU'
complete -c nirux -n __fish_use_subcommand -a rollback -d 'Restore previous generation'
complete -c nirux -n __fish_use_subcommand -a status -d 'Show installed components'
complete -c nirux -n __fish_use_subcommand -a doctor -d 'Diagnose the session'
complete -c nirux -n __fish_use_subcommand -a uninstall -d 'Remove NIRU'
complete -c nirux -n __fish_use_subcommand -a help -d 'Show usage'
complete -c nirux -n '__fish_seen_subcommand_from install update' -l browser -a 'helium none keep' -d 'Browser policy'
complete -c nirux -n '__fish_seen_subcommand_from install' -l display-manager -a 'auto startx sddm lightdm' -d 'Session entry'
complete -c nirux -n '__fish_seen_subcommand_from install update' -l release -d 'Release version'
complete -c nirux -n '__fish_seen_subcommand_from install update' -l no-packages -d 'Do not install OS packages'
complete -c nirux -n '__fish_seen_subcommand_from uninstall' -l purge -d 'Remove NIRU-owned settings and wallpapers'
