Vagrant.configure("2") do |config|
  # Kullanılacak Ubuntu imajı
  config.vm.box = "ubuntu/jammy64"

  # Ekranın gelmesini sağlayan GUI modu
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = "2048"
    vb.cpus = 2
  end

  # İŞTE EKSİK OLAN KISIM:
  # Bu blok, Vagrant'a Ubuntu'nun içine Ansible kurmasını 
  # ve playbook.yml dosyasını çalıştırmasını söyler.
  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "playbook.yml"
    ansible.install = true
  end
end