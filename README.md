# Staj Görevleri Dokümantasyonu

## Task 1: Otomatik Kubernetes Ortamı Kurulumu (Vagrant & Ansible & k3s)

Bu proje, Infrastructure as Code (IaC) ve Configuration Management prensiplerini kullanarak yerel geliştirme ortamında sıfırdan bir Kubernetes (k3s) kümesi oluşturma sürecini otomatize eder. Vagrant ile sanal makine provizyonlanmış, Ansible ile gerekli bağımlılıklar ve k3s kurulumu yapılandırılmıştır.

### 📋 İçindekiler

1. [Kullanılan Teknolojiler](#-kullanılan-teknolojiler)
2. [Adım 1: Sanallaştırma ve Vagrant Ortamının Hazırlanması](#-adım-1-sanallaştırma-ve-vagrant-ortamının-hazırlanması)
3. [Adım 2: Ansible Kurulumu ve Konfigürasyon Yönetimi](#-adım-2-ansible-kurulumu-ve-konfigürasyon-yönetimi)
4. [Adım 3: Ansible Playbook ile Otomatik k3s Kurulumu](#-adım-3-ansible-playbook-ile-otomatik-k3s-kurulumu)
5. [Adım 4: Doğrulama ve Test](#-adım-4-doğrulama-ve-test)
6. [🧠 Teorik Soru & Cevaplar](#-teorik-soru--cevaplar)

### 🛠 Kullanılan Teknolojiler

| Bileşen | Teknoloji |
|---|---|
| Hipervizör | Oracle VirtualBox |
| Provizyon Aracı | Vagrant |
| İşletim Sistemi | Ubuntu 22.04 (Jammy Jellyfish) |
| Konfigürasyon Yönetimi | Ansible |
| Kubernetes Dağıtımı | k3s (Hafif ve CNCF uyumlu K8s dağıtımı) |

### 📦 Adım 1: Sanallaştırma ve Vagrant Ortamının Hazırlanması

Yerel ana makinede (Windows/macOS) VirtualBox ve Vagrant kurularak Ubuntu tabanlı sanal makinenin altyapısı kod (`Vagrantfile`) ile tanımlandı.

**`Vagrantfile` Yapılandırması**

Sanal makinenin donanım kaynakları (CPU, RAM) ve ağ ayarları tanımlandı.

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = "2048"
    vb.cpus = 2
  end
  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "playbook.yml"
    ansible.install = true
  end
end
```

Sanal makineyi başlatma ve SSH ile bağlanma:

```bash
vagrant provision
vagrant up
vagrant ssh
```

### ⚙️ Adım 2: Ansible Kurulumu ve Konfigürasyon Yönetimi

Vagrant sayesinde Ansible, sanal makine ilk başlarken otomatik olarak kuruldu (`ansible_local` provisioner üzerinden).

### 🚀 Adım 3: Ansible Playbook ile Otomatik k3s Kurulumu

Ansible kullanılarak hafif bir Kubernetes dağıtımı olan k3s'in sunucuya kurulumu için bir YAML playbook hazırlandı (bu dosya Vagrant dizininde oluşturuldu).

**Sistemi Tek Komutla Ayağa Kaldırma**

Vagrantfile ve playbook hazırlandıktan sonra süreç başlatıldı. `vagrant up` komutu hem sanal makineyi oluşturdu hem de içerisine Ansible'ı kurdu. Ardından playbook çalıştırılarak Kubernetes yapılandırıldı.

```bash
# 1. Sanal makineyi başlatma ve Ansible'ı otomatik kurma
vagrant up

# 2. Sanal makineye SSH ile bağlanma
vagrant ssh

# 3. K3s kurulum playbook'unu çalıştırma (sanal makine içinde)
ansible-playbook /vagrant/playbook.yaml
```

### ✅ Adım 4: Doğrulama ve Test

```bash
kubectl get nodes
kubectl get pods -A
```
<img width="542" height="56" alt="image" src="https://github.com/user-attachments/assets/57ae49bd-0d47-4215-94fd-a5b1fb2fba52" />


### 🧠 Teorik Soru & Cevaplar

**S1: Ansible'ı Vagrant içinden kurmanın (Provisioning) bize sağladığı avantaj nedir?**

Sunucuya manuel olarak SSH ile bağlanıp `apt install ansible` komutunu çalıştırmak "Zero-Touch Provisioning" (Sıfır Dokunuşla Kurulum) mantığına aykırıdır. Vagrant'ın provision özelliğini kullanmak, `vagrant up` dediğimiz anda işletim sisteminin, bağımlılıkların ve Ansible'ın insan müdahalesi olmadan hazır hale gelmesini sağlar. Tam bir otomasyon zinciri kurulmuş olur.

**S2: Neden bash scriptleri yerine Ansible Playbook kullandık?**

Manuel kurulumlar (bash scriptleri) insan hatasına açıktır ve aynı sunucuyu birden fazla kez kurmak gerektiğinde (Idempotency - Eş Etkililik) zorluk çıkarır. Ansible playbook'ları declarative (bildirimsel) bir yapı sunar; sistemin olması gerektiği nihai durumu tanımlar. Eğer k3s zaten kuruluysa tekrar kurmaya çalışmaz, sadece eksik olan adımları tamamlar.

---

## Task 2: Helm ile Uygulama Yönetimi ve Chart Geliştirme

Bu görev, Kubernetes üzerinde paket yönetimi süreçlerini otomatize etmek için **Helm** kullanımını kapsar. Çalışma kapsamında; resmi Helm depolarından (ArtifactHub/Bitnami) uygulama dağıtımı, konfigürasyonların `values.yaml` üzerinden yönetilmesi, sıfırdan özel Helm Chart geliştirilmesi (Go Templating), versiyon kontrolü / kriz anı rollback operasyonları ve çok katmanlı (stateful) sistemlerin Kubernetes Secret objesiyle güvenli mimaride ayağa kaldırılması gerçekleştirilmiştir.

### 📋 İçindekiler

1. [Kullanılan Teknolojiler](#-kullanılan-teknolojiler-1)
2. [Adım 1: Bitnami Reposu ile Nginx Dağıtımı ve Kontrolü](#-adım-1-bitnami-reposu-ile-nginx-dağıtımı-ve-kontrolü)
3. [Adım 2: Ölçekleme ve Kaynak Limitlerinin Yapılandırılması](#-adım-2-ölçekleme-ve-kaynak-limitlerinin-yapılandırılması)
4. [Adım 3: Kendi Helm Chart'ımızı Oluşturma ve Go Templating](#-adım-3-kendi-helm-chartımızı-oluşturma-ve-go-templating)
5. [Adım 4: Hata Simülasyonu ve Rollback (Sürüm Geri Alma)](#-adım-4-hata-simülasyonu-ve-rollback-sürüm-geri-alma)
6. [Adım 5: WordPress + MariaDB Full-Stack ve Secret Yönetimi](#-adım-5-wordpress--mariadb-full-stack-ve-secret-yönetimi)
7. [🧠 Teorik Soru & Cevaplar](#-teorik-soru--cevaplar-1)

### 🛠 Kullanılan Teknolojiler

| Bileşen | Teknoloji |
|---|---|
| Paket Yöneticisi | Helm (v3) |
| Konteyner Orkestrasyonu | Kubernetes (k3s) |
| Uygulamalar | Nginx, WordPress, Redis, MariaDB |
| Depo (Repository) | Bitnami (ArtifactHub) |

### 🔧 Adım 0: Helm CLI Kurulumu
 
İlk olarak sanal makinenin içine Helm CLI aracını kuralım.
 
Sanal makinede (`vagrant ssh` ile bağlıyken) aşağıdaki komutları sırasıyla çalıştır:
 
**1. Kurulum Betiğini İndir ve Çalıştır**
 
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```
 
**2. Kurulumu Doğrula**
 
```bash
helm version
```

### 📦 Adım 1: Bitnami Reposu ile Nginx Dağıtımı ve Kontrolü

Endüstri standardı olan Bitnami deposu Kubernetes kümemize eklenerek, Helm aracılığıyla temel bir Nginx web sunucusu ayağa kaldırıldı.

```bash
# 1. Bitnami reposunu ekleme ve depoyu güncelleme
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# 2. Nginx Chart'ını varsayılan ayarlarla kurma
helm install my-nginx bitnami/nginx

# 3. Helm listesi ve uygulama durumunu kontrol etme
helm list
helm status my-nginx
helm status my-redis
```

### 📈 Adım 2: Ölçekleme ve Kaynak Limitlerinin Yapılandırılması

Yüksek erişilebilirlik (High Availability) ve kaynak yönetimi senaryosu kapsamında, oluşturduğumuz Nginx uygulamasının replika sayısı artırıldı ve CPU/RAM limitleri belirlendi.

**`nginx-values.yaml` Konfigürasyonu**

Uygulamanın `values.yaml` şablonunu ezmek (override) için kendi dosyamızı oluşturduk:

```yaml
replicaCount: 2
resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

**`redis-values.yaml` Konfigürasyonu**

Uygulamanın `redis.yaml` şablonunu ezmek (override) için kendi dosyamızı oluşturduk:

```yaml
replicaCount: 2
resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

### 🧩 Adım 3: Kendi Helm Chart'ımızı Oluşturma ve Go Templating

Dışarıdan hazır paket kullanmak yerine, sıfırdan `hello-app` isminde bir Helm Chart oluşturularak Go Templating mimarisi test edildi.

**1. Chart İskeletini Oluşturma**

```bash
helm create hello-app
cd hello-app
```

**2. Şablonlaştırma (Go Templating) Entegrasyonu**

Statik kod yerine değişkenleri `values.yaml`'dan alan dinamik bir ConfigMap ve yapılandırma oluşturduk.

`values.yaml` (Değişkenler):

```yaml
customConfig:
  message: "Hello World! Helm ve Go Templating basariyla calisiyor."
  environment: "Development"
```

`templates/configmap.yaml` (Şablon):

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-html
data:
  index.html: |
    <html>
      <body>
        <h1>{{ .Values.customConfig.message }}</h1>
        <p>Ortam: <b>{{ .Values.customConfig.environment }}</b></p>
      </body>
    </html>
```

**3. Statik Analiz ve Kurulum**

```bash
# Chart yapısını ve sözdizimi hatalarını test etme
helm lint .
```

<img width="663" height="256" alt="helm lint sonucu" src="https://github.com/user-attachments/assets/cf2994c2-17ee-484b-a028-496667c42451" />

```bash
# Uygulamayı kümeye dağıtma
helm install my-hello-release .
```

### 🔄 Adım 4: Hata Simülasyonu ve Rollback (Sürüm Geri Alma)

Canlı ortam kriz senaryosu simüle edildi. Sisteme kasıtlı olarak var olmayan bir Docker imajı gönderilip sistemin çökmesi sağlandı, ardından Helm sürüm geçmişi kullanılarak kurtarma işlemi yapıldı.

```bash
# 1. Hatalı imaj versiyonu ile sistemi bozma
helm upgrade my-hello-release . --set image.tag="hatali-surum-999"

# 2. Hata durumunu gözlemleme (ImagePullBackOff hatası)
kubectl get pods

# 3. Helm sürüm geçmişini kontrol etme
helm history my-hello-release

# 4. Çalışan kararlı sürüme (Revizyon 1 veya 2) geri dönme
helm rollback my-hello-release 1

# 5. İyileşmeyi doğrulama
kubectl get pods
```
<img width="1025" height="123" alt="image" src="https://github.com/user-attachments/assets/f2d077b9-2b74-44ce-b69a-3302a2e46d4e" />


### 🔐 Adım 5: WordPress + MariaDB Full-Stack ve Secret Yönetimi

En önemli DevOps pratiklerinden biri olan güvenli kimlik yönetimi uygulandı. MariaDB ve WordPress şifreleri plain-text (açık metin) olarak YAML dosyalarına yazılmak yerine, Kubernetes Secret objesi üzerinden yapılandırıldı.

**1. Kubernetes Secret Objesini Oluşturma**

```bash
kubectl create secret generic wp-db-secret \
  --from-literal=mariadb-root-password='GucluRootSifresi123!' \
  --from-literal=mariadb-password='GucluWpDbSifresi123!' \
  --from-literal=wordpress-password='AdminGucluSifre123!'
```
<img width="600" height="61" alt="image" src="https://github.com/user-attachments/assets/ffe82af3-25dc-4d7e-a115-34cb27d72444" /> : secret objesi oluşturuldu.


**2. `wp-values.yaml` ile Mimari Bağlantı**

Chart içindeki bileşenlere şifreyi nereden okuyacaklarını belirten ayar dosyamızı hazırladık:

```yaml
# WordPress Yönetici Ayarları
wordpressUsername: admin
existingSecret: wp-db-secret
wordpressSecretKey: wordpress-password

# MariaDB (Veritabanı) Ayarları
mariadb:
  enabled: true
  auth:
    existingSecret: wp-db-secret
    rootPasswordSecretKey: mariadb-root-password
    passwordSecretKey: mariadb-password
    database: bitnami_wordpress
    username: bn_wordpress

service:
  type: ClusterIP
```

**3. Kurulum ve Web Arayüzüne Erişim**

```bash
# Helm ile full-stack kurulumu başlatma
helm install my-wordpress bitnami/wordpress -f wp-values.yaml

# Pod'ların Running durumuna geçmesini bekleme
kubectl get pods -w

# Kendi tarayıcımızdan erişebilmek için ağ tüneli (port-forward) açma
kubectl port-forward svc/my-wordpress 8081:80 &
```

> **Panel Adresi:** http://localhost:8081/wp-admin
> **Giriş Bilgileri:** Kullanıcı: `admin` | Şifre: `AdminGucluSifre123!`

<img width="1900" height="963" alt="wordpress-ekran" src="https://github.com/user-attachments/assets/72ab7037-2411-4a80-a206-176610f845a8" />


### 🧠 Teorik Soru & Cevaplar

**S1: Helm kullanmanın düz Kubernetes Manifest dosyalarına (YAML) göre en büyük avantajı nedir?**

Düz YAML dosyaları statiktir. Ortamlar arası (Dev, Test, Prod) geçiş yaparken YAML dosyalarını elle kopyalayıp değiştirmek gerekir. Helm ise Go Templating sayesinde dinamiktir; aynı şablonu kullanarak sadece `values.yaml` dosyasını değiştirerek yüzlerce farklı konfigürasyonda dağıtım yapmayı sağlar. Ayrıca uygulama yaşam döngüsünü (install, upgrade, rollback) tek merkezden yönetir.

**S2: `helm rollback` komutu arka planda nasıl çalışır? Sistemi nasıl kurtarır?**

Helm, yapılan her `install` veya `upgrade` işlemini Kubernetes kümesi içerisinde (Secret veya ConfigMap olarak) bir "revizyon" geçmişi olarak saklar. Hata yapıp `helm rollback <revizyon_no>` dediğimizde, Helm istenilen eski revizyonun yapılandırma dosyasını bellekten geri çağırır ve bu durumu bir `upgrade` komutu gibi sisteme basarak bozuk pod'ları yok eder, sağlıklı pod'ları yeniden yaratır.

**S3: ConfigMap ve Secret arasındaki kullanım farkı nedir? Veritabanı şifresi için neden Secret kullandık?**

ConfigMap; port numaraları, dosya yolları, ortam türü (dev/prod) gibi hassas olmayan verileri tutmak içindir. İçeriği açıkça okunabilir.

Secret ise; API anahtarları, sertifikalar ve parolalar için tasarlanmıştır. Verileri base64 formatında tutar, diske yazılmaz (tmpfs üzerinde çalışır) ve K8s Role-Based Access Control (RBAC) kurallarıyla sadece yetkili kullanıcı ve pod'ların okumasına izin verecek şekilde güvenliği artırır.
