set --universal nvm_default_version lts # or whatever version you use

set -gx EDITOR nvim

printf "\e[2 q"

function fish_greeting
    fastfetch
end

if status is-login
    if test (tty) = /dev/tty1
        start-hyprland
    end
end
