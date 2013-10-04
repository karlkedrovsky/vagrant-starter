echo "[vagrant provisioning] Setting git config variables..."
git config --global user.name "Karl Kedrovsky"
git config --global user.email karl@kedrovsky.com

echo "[vagrant provisioning] Setting up custom config files..."
git clone -q https://github.com/karlkedrovsky/oh-my-zsh.git /home/vagrant/oh-my-zsh
git clone -q https://github.com/karlkedrovsky/config.git /home/vagrant/config
ln -s /home/vagrant/config/zshrc /home/vagrant/.zshrc
ln -s /home/vagrant/config/aliases /home/vagrant/.aliases
ln -s /home/vagrant/config/drush /home/vagrant/.drush

echo "[vagrant provisioning] Setting vagrant shell to zsh..."
chsh -s /usr/bin/zsh vagrant
