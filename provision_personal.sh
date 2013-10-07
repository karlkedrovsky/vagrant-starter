echo "[vagrant provisioning] Setting git config variables..."
sudo -u vagrant git config --global user.name "Karl Kedrovsky"
sudo -u vagrant git config --global user.email karl@kedrovsky.com

echo "[vagrant provisioning] Setting up custom config files..."
sudo -u vagrant git clone -q https://github.com/karlkedrovsky/oh-my-zsh.git /home/vagrant/oh-my-zsh
sudo -u vagrant git clone -q https://github.com/karlkedrovsky/config.git /home/vagrant/config
sudo -u vagrant ln -s /home/vagrant/config/zshrc /home/vagrant/.zshrc
sudo -u vagrant ln -s /home/vagrant/config/aliases /home/vagrant/.aliases
sudo -u vagrant ln -s /home/vagrant/config/drush /home/vagrant/.drush

echo "[vagrant provisioning] Setting vagrant shell to zsh..."
chsh -s /usr/bin/zsh vagrant
