##
echo "Setting up SSH authentication for Git..."

# Check if SSH key already exists
if [[ -f "${HOME}/.ssh/id_ed25519" ]]; then
    echo "SSH key already exists at ~/.ssh/id_ed25519"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Displaying existing public key:"
        cat "${HOME}/.ssh/id_ed25519.pub"
        echo
        echo "Add this key to your Git hosting service (GitHub, GitLab, etc.)"
        return 0
    fi
fi

# Prompt for email address
read -p "Enter your email address: " email
if [[ -z "${email}" ]]; then
    echo "ERROR: Email address is required"
    exit 1
fi

# Ensure .ssh directory exists
mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

# Generate SSH key
echo "Generating SSH key..."
ssh-keygen -t ed25519 -C "${email}" -f "${HOME}/.ssh/id_ed25519"

# Display public key
echo
echo "Your public SSH key:"
echo "===================="
cat "${HOME}/.ssh/id_ed25519.pub"
echo "===================="
echo
echo "Add this key to https://github.com/settings/ssh/new"
echo
read -p "Press any key to continue: " foo


# Load the dotfiles
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:BlakeJC94/dotfiles.git

# Install brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install brew tools
/bin/bash ~/.brew
