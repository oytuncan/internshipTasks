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

# Staj Görevleri Raporu — Task 3 & Task 4

Bu doküman, staj sürecinde tamamlanan **Task 3 (Gözlemlenebilirlik: Monitoring/Logging/Alerting)** ve **Task 4 (CI/CD & GitOps)** görevlerinin adım adım özetidir. İlgili adımların çıktı ekran görüntüleri (`.jpg`) ilerleyen düzenlemede ilgili bölümlerin altına eklenecektir.

> ⚠️ **Güvenlik notu:** Bu rapor GitHub'da herkese açık paylaşılacağı için orijinal notlardaki gerçek parolalar ve GitHub token'ı burada **placeholder** (örn. `<MINIO_ROOT_PASSWORD>`) ile değiştirildi. Gerçek değerleri repo geçmişinden de temizlemeyi (ör. commit'i squash'lamak veya secret'ı iptal edip yenisini üretmek) unutma — paylaştığın token hâlâ notlarda açık haldeydi, GitHub'a push etmeden önce o token'ı iptal edip yenisini oluşturman güvenlik açısından önemli.

---

## Task 3 — Gözlemlenebilirlik (Observability) Altyapısı

### Genel Mimari

```
[ Podlar / Node'lar ] ──(Metrikler)──> [ Prometheus ] ───┐
                                                          ├──> [ MinIO (90 Gün) ]
[ Podlar / Node'lar ] ──(Loglar)────> [ Promtail → Loki ] ┘
                                            │
                                            ▼
                                     [ Grafana ] (Grafikler & Arama)
                                            │
                                     [ Alertmanager ] ──> [ E-Posta Bildirimi ]
```

### 1. Namespace ve Helm Depolarının Hazırlanması

İzleme araçlarını sistem servislerinden ayırmak için ayrı bir `monitoring` namespace'i açıldı ve gerekli resmi Helm depoları eklendi:

```bash
kubectl create namespace monitoring

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add minio https://charts.min.io/
helm repo update
```

Ayarları düzenli tutmak için ayrı bir çalışma dizini oluşturuldu:

```bash
mkdir -p ~/monitoring-lab
cd ~/monitoring-lab
```

<!-- Ekran görüntüsü: namespace ve repo ekleme çıktısı -->

### 2. MinIO (Object Storage) Kurulumu

Metrik ve logların uzun süreli (90 gün) saklanacağı S3 uyumlu depolama katmanı olarak MinIO, tek node (standalone) modunda kuruldu.

`minio-values.yaml`:

```yaml
mode: standalone
replicas: 1

rootUser: "admin"
rootPassword: "<MINIO_ROOT_PASSWORD>"

persistence:
  enabled: true
  size: 10Gi

defaultBuckets: "k8s-metrics,k8s-logs"

resources:
  requests:
    memory: 256Mi
    cpu: 100m
  limits:
    memory: 512Mi
    cpu: 250m
```

```bash
helm install minio minio/minio -n monitoring -f minio-values.yaml
```

<!-- Ekran görüntüsü: MinIO pod durumu -->

### 3. Prometheus & Grafana Kurulumu

VM kaynaklarını (RAM/CPU) zorlamayacak şekilde optimize edilmiş bir `kube-prometheus-stack` yapılandırması hazırlandı. 90 günlük saklama süresi, hafif kaynak limitleri ve K3s ile çakışan gereksiz bileşenlerin (kube-controller-manager, kube-scheduler, kube-etcd) devre dışı bırakılması bu adımda ele alındı.

`prometheus-values.yaml`:

```yaml
prometheus:
  prometheusSpec:
    retention: 90d
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
      limits:
        cpu: 500m
        memory: 1024Mi

grafana:
  adminUser: "admin"
  adminPassword: "<GRAFANA_ADMIN_PASSWORD>"
  service:
    type: ClusterIP

alertmanager:
  alertmanagerSpec:
    resources:
      requests:
        cpu: 50m
        memory: 64Mi
      limits:
        cpu: 100m
        memory: 128Mi

kubeControllerManager:
  enabled: false
kubeScheduler:
  enabled: false
kubeEtcd:
  enabled: false
```

```bash
helm install monitoring-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f ~/monitoring-lab/prometheus-values.yaml
```

<!-- Ekran görüntüsü: kube-prometheus-stack pod durumu -->

### 4. Grafana Paneline Erişim (Port Forwarding)

Windows tarayıcısından Grafana'ya erişmek için iki katmanlı bir SSH/port-forward köprüsü kuruldu:

```bash
# VM içinde: Grafana servisini 3000 portuna yönlendir
kubectl port-forward -n monitoring svc/monitoring-stack-grafana 3000:80 &

# Windows tarafında: VM'e tünel aç
vagrant ssh -- -L 3000:localhost:3000
```

```
[ Windows Tarayıcı ] → (vagrant ssh -L 3000:localhost:3000) → [ Ubuntu VM ] → (kubectl port-forward 3000:80) → [ Grafana Pod ]
```

<!-- Ekran görüntüsü: Grafana giriş ekranı -->

### 5. Kaynak Optimizasyonu

İzleme yığını (Prometheus + Grafana + MinIO) çalışırken VM belleği yetersiz kaldığı için `Vagrantfile` üzerinden VM RAM'i 2 GB'tan 4 GB'a çıkarıldı:

```ruby
config.vm.provider "virtualbox" do |vb|
  vb.gui = false
  vb.memory = "4096"
  vb.cpus = 2
end
```

### 6. Loki ve Promtail Kurulumu (Log Toplama)

```bash
helm install loki-stack grafana/loki-stack \
  -n monitoring \
  --set promtail.enabled=true \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=5Gi
```

Grafana'ya veri kaynağı olarak Prometheus şu adresten eklendi:
`http://monitoring-stack-kube-prom-prometheus.monitoring:9090`

Loglar Grafana **Explore** ekranında LogQL ile sorgulanarak `error` ve `info` seviyesindeki kayıtlar zaman çizelgesine dökülüp incelendi.

**Kavramsal notlar:**
- **rsyslogd:** Linux'ta kernel, servis ve arka plan uygulamalarının ürettiği sistem günlüklerini toplayıp yerel diske veya uzak bir sunucuya (TCP/UDP) ileten geleneksel loglama servisi.
- **Search Engine (Arama Motoru):** Büyük hacimli yapılandırılmamış/yarı yapılandırılmış veriyi (log, metin) indeksleyerek milisaniyeler içinde anahtar kelime, filtre veya zaman aralığı bazlı arama imkânı sunan sistem (örn. Elasticsearch, OpenSearch, Loki).

<img width="1504" height="902" alt="mem-usage-graph" src="https://github.com/user-attachments/assets/31d89587-6452-4d24-8a68-bb6d2af5dd20" />

<img width="1518" height="1016" alt="erfo_grafik" src="https://github.com/user-attachments/assets/ffc2c878-f15f-461a-8d32-2f35632fe9a6" />

<img width="1486" height="912" alt="error" src="https://github.com/user-attachments/assets/1dc69a5b-51da-4d45-a3e2-0dab88d8b13b" />

<!-- Ekran görüntüsü: Grafana Explore - LogQL sorgu sonucu -->

### 7. Alarm Kuralları (PrometheusRule)

CPU (`> %200`, 5 dk) ve Memory (`> %90`, 1 dk) eşiklerini izleyen alarm kuralları `PrometheusRule` kaynağı olarak tanımlandı:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: custom-cluster-alerts
  namespace: monitoring
  labels:
    release: monitoring-stack
spec:
  groups:
  - name: resource-usage-alerts
    rules:
    - alert: HighCPUUsage
      expr: sum(rate(container_cpu_usage_seconds_total{container!=""}[5m])) by (pod, namespace) > 2
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} aşırı CPU tüketiyor"
        description: "Pod CPU tüketimi 5 dakikadır 2 tam çekirdeğin (%200) üzerinde."

    - alert: HighMemoryUsage
      expr: (sum(container_memory_working_set_bytes{container!=""}) by (pod, namespace) / sum(container_spec_memory_limit_bytes{container!=""} > 0) by (pod, namespace)) * 100 > 90
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} %90 bellek sınırını aştı"
        description: "Pod bellek kullanımı 1 dakikadır %90 eşiğinin üzerinde (OOMKilled riski)."
```

```bash
kubectl apply -f ~/custom-alert-rules.yaml
```

<img width="1331" height="722" alt="Ekran görüntüsü 2026-09-02 150953" src="https://github.com/user-attachments/assets/136cc496-d394-409a-be35-746e949d6b0a" />

### 8. Test: Sentetik Bellek Yükü

Alarm kuralını doğrulamak için 150Mi limitli, ~138Mi (%92) bellek tüketen bir test pod'u ayağa kaldırıldı:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: memory-load-test
  namespace: default
spec:
  containers:
  - name: mem-stress
    image: python:3.9-slim
    command: ["python", "-c"]
    args:
    - |
      import time
      data = b'x' * (138 * 1024 * 1024)
      print("Bellek tahsis edildi (%92), yük 10 dakika boyunca tutuluyor...")
      time.sleep(600)
    resources:
      requests:
        memory: "100Mi"
      limits:
        memory: "150Mi"
```

<!-- Ekran görüntüsü: memory-load-test pod durumu -->

### 9. Grafana Ingress ile Kalıcı Erişim (Traefik)

Port-forward yerine kalıcı erişim için K3s'in varsayılan Ingress Controller'ı **Traefik**, Grafana'ya bağlandı:

```bash
helm upgrade --reuse-values monitoring-stack prometheus-community/kube-prometheus-stack -n monitoring \
  --set grafana.ingress.enabled=true \
  --set grafana.ingress.ingressClassName=traefik \
  --set grafana.ingress.hosts="{grafana.local}"
```

Doğrulama adımları:

```bash
kubectl get ingress -n monitoring
curl -I -H "Host: grafana.local" http://localhost
```

<img width="1457" height="902" alt="graf-dash" src="https://github.com/user-attachments/assets/025eccd8-29b5-4e62-9442-1b906579e4e6" />


### 10. Canlı Alarm Testi (stress-ng)

Bellek alarmını canlı tetiklemek ve e-posta bildirim akışını doğrulamak için kontrollü bir yük testi yapıldı:

```bash
sudo apt-get update && sudo apt-get install -y stress-ng
stress-ng --vm 1 --vm-bytes 92% --timeout 120s
```

**Bildirim zinciri:** Grafana üzerinde Gmail SMTP entegrasyonu ile e-posta gönderimi yapılandırıldı; Contact Points altında hedef e-posta adresi (`<ALERT_EMAIL_ADDRESS>`) tanımlanarak Notification Policy (Root Policy) tüm alarmları bu kanala yönlendirecek şekilde güncellendi.

<img width="1513" height="704" alt="krtik-bellek-kul-mail" src="https://github.com/user-attachments/assets/6ed79c3b-9cf4-4b76-83a3-2fb0a68cb754" />

<img width="1480" height="736" alt="yüksek-cpu-kul-mail" src="https://github.com/user-attachments/assets/d6476a43-5eaa-4508-b082-f6a1ee838162" />

### 11. Uzun Vadeli Metrik Depolama (Thanos + MinIO)

```
[ Prometheus ] (Sadece son 24 saati tutar, diski şişirmez)
      │
      ▼
[ Thanos Sidecar ] (Her 2 saatte bir dolan veriyi paketleyen kurye)
      │
      ▼ (Ağ üzerinden taşır)
[ MinIO ] (Kümenin özel S3 deposu)
      ▲
      │ (Düzenli denetler)
[ Thanos Compactor ] (90 günden eski dosyaları MinIO'dan silen temizlikçi)
```

### 12. Loki Log Depolamasını MinIO'ya Taşıma

Mimari: **Promtail** tüm node/pod loglarını toplayıp **Loki**'ye iletir; **Loki** logları MinIO'daki `loki` bucket'ına yazar ve **90 gün (2160 saat)** sonunda otomatik temizler.

```
[ Pod & Node Logları ]
         │
         ▼
[ Promtail (DaemonSet) ]
         │
         ▼
[ Grafana Loki ]
         │
         ▼ (90 gün saklama)
[ MinIO ] ('loki' bucket)
```

1) MinIO'da `loki` bucket'ının oluşturulması:

```bash
kubectl run minio-create-loki-bucket --rm -it --restart='Never' \
  --image=minio/mc --namespace=monitoring \
  --command -- sh -c 'mc alias set myminio http://minio.monitoring.svc.cluster.local:9000 admin "<MINIO_ROOT_PASSWORD>" && mc mb myminio/loki'
```
<img width="1898" height="879" alt="image" src="https://github.com/user-attachments/assets/e0206370-e227-4161-bd4b-b2a63f4d00b5" />

2) `loki-values.yaml` — S3 (MinIO) backend, SingleBinary mod ve 90 günlük retention:

```yaml
loki:
  auth_enabled: false
  commonConfig:
    replication_factor: 1
  schemaConfig:
    configs:
      - from: "2024-01-01"
        store: tsdb
        object_store: s3
        schema: v13
        index:
          prefix: index_
          period: 24h
  storage:
    type: s3
    bucketNames:
      chunks: loki
      ruler: loki
      admin: loki
    s3:
      endpoint: minio.monitoring.svc.cluster.local:9000
      accessKeyId: admin
      secretAccessKey: "<MINIO_ROOT_PASSWORD>"
      s3ForcePathStyle: true
      insecure: true
  limits_config:
    retention_period: 2160h
    allow_structured_metadata: false
  compactor:
    retention_enabled: true
    delete_request_cancel_period: 0s
    retention_delete_delay: 2h

deploymentMode: SingleBinary
singleBinary:
  replicas: 1
  persistence:
    size: 5Gi

backend:
  replicas: 0
read:
  replicas: 0
write:
  replicas: 0
chunksCache:
  enabled: false
resultsCache:
  enabled: false
gateway:
  enabled: false
```

3) Kurulum:

```bash
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo update
helm install loki grafana/loki -n monitoring -f loki-values.yaml
```

4) Promtail agent kurulumu:

```yaml
# promtail-values.yaml
config:
  clients:
    - url: http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push
```

```bash
helm install promtail grafana/promtail -n monitoring -f promtail-values.yaml
```

5) Doğrulama:

```bash
kubectl get pods -n monitoring -l "app.kubernetes.io/name in (loki, promtail)"
```

<!-- Ekran görüntüsü: loki-0 ve promtail pod'larının 1/1 Running durumu -->

---

## Task 4 — CI/CD & GitOps Pipeline

### Genel Bakış ve Hedef

Amaç: GitHub'a kod push edildiği andan itibaren, uygulamanın (WordPress) derlenip K3s kümesinde sıfır el müdahalesiyle güncellenmesini sağlayan tam otomatik bir GitOps boru hattı kurmak.

Kurulum sırası:
1. **Harbor** — özel container image registry
2. **Argo CD** — GitOps dağıtım motoru
3. **GitHub hazırlığı** — PAT / repo yapılandırması
4. **ARC (Actions Runner Controller)** — küme içinde self-hosted GitHub Actions runner'ları
5. **CI/CD workflow** — image build → Harbor'a push → `values.yaml` güncelleme
6. **Uçtan uca test**

```
[ Oytun (Geliştirici) ]
          │  1. git push
          ▼
┌──────────────────────────────────────────────────────────┐
│                     GITHUB DEPOSU                        │
│ Dockerfile · helm/values.yaml · .github/workflows/ci-cd.yaml │
└──────────────────────────────────────────────────────────┘
          │                                      ▲
          │ 2. Workflow tetiklenir               │ 5. Runner, yeni imaj etiketini
          ▼                                      │    values.yaml'a yazar ve push'lar
┌─────────────────────────────────────────┐      │
│         K3S KÜMESİ (Sanal Makine)       │      │
│  🤖 Self-hosted Runner ──3. docker build─┴──────┘
│           │ 4. docker push
│           ▼
│  🐳 Harbor (wordpress projesi)  ◀── 7. imajı çeker
│           ▲
│  🐙 Argo CD ── 6. Git değişikliğini fark eder (Sync) ──┘
│           │
│           ▼ 8. yeni sürümü uygular
│  🌐 WordPress Pod
└─────────────────────────────────────────┘
```

### 1. Harbor Image Registry Kurulumu

Namespace ve Helm deposu:

```bash
kubectl create namespace harbor
helm repo add harbor https://helm.goharbor.io
helm repo update
```

`harbor-values.yaml` — Traefik üzerinden `harbor.local` ile HTTP erişim, gereksiz güvenlik tarayıcılarının (Trivy/Notary/Chartmuseum) kapatılması, VM kaynaklarına göre optimize edilmiş kalıcı depolama:

```yaml
expose:
  type: ingress
  tls:
    enabled: false
  ingress:
    hosts:
      core: harbor.local
    controller: default
externalURL: http://harbor.local

trivy:
  enabled: false
notary:
  enabled: false
chartmuseum:
  enabled: false

persistence:
  enabled: true
  resourcePolicy: keep
  persistentVolumeClaim:
    registry:
      size: 5Gi
    database:
      size: 1Gi
    redis:
      size: 1Gi

harborAdminPassword: "<HARBOR_ADMIN_PASSWORD>"
```

```bash
helm install harbor harbor/harbor -n harbor -f harbor-values.yaml
kubectl get pods -n harbor -w
```

`registries.yaml` üzerinden K3s'in containerd motoruna Harbor'dan HTTP ile imaj çekme izni verildi, Harbor içinde `wordpress` adında bir proje oluşturuldu.

<!-- Ekran görüntüsü: Harbor pod durumları (core/portal/registry/database/redis Running) -->

### 2. Ağ ve Ingress Yönetimi

Traefik Ingress Controller'ın `harbor.local` ve `argocd.local` adreslerini doğru yönlendirdiği doğrulandı, Windows `hosts` dosyası ve VM arası port yönlendirmesi ile bu adreslerin tarayıcıdan erişilebilir olması sağlandı.

```bash
kubectl get ingress -A
```

```bash
# Windows tarafında (proje dizininden)
vagrant ssh -- -N -L 80:10.0.2.15:80
```

<!-- Ekran görüntüsü: kubectl get ingress -A çıktısı -->

### 3. Argo CD Kurulumu

Argo CD Helm ile kuruldu, Traefik ile çakışmaması için `insecure` modda yapılandırıldı ve ilk admin şifresi alındı. Argo CD, Git reposundaki Helm `values.yaml` dosyasını sürekli izleyerek yeni bir imaj etiketi gördüğünde bunu otomatik olarak kümeye uygular — böylece Git reposu sistemin "tek doğruluk kaynağı" (single source of truth) haline gelir.

<!-- Ekran görüntüsü: Argo CD giriş ekranı -->

### 4. GitHub Hazırlığı ve cert-manager

GitHub tarafında bir **Personal Access Token (classic)** üretildi (`repo`, `workflow`, `admin:repo_hook` scope'ları ile), ve ARC'nin webhook/sertifika yönetimi için kümeye `cert-manager` kuruldu:

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.yaml
kubectl get pods -n cert-manager
```

> Not: Bu notlarda geçen gerçek PAT (`ghp_...`) değeri repoya **kesinlikle eklenmedi**; sadece Kubernetes Secret olarak kümeye tanımlandı. Bu README için tüm gerçek token/parola değerleri placeholder ile değiştirildi.

### 5. Actions Runner Controller (ARC) Kurulumu

```bash
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm repo update

kubectl create namespace actions-runner-system

helm install arc actions-runner-controller/actions-runner-controller \
  --namespace actions-runner-system

kubectl create secret generic controller-manager \
  -n actions-runner-system \
  --from-literal=github_token="<GITHUB_PAT>"
```

Runner pod'ları `2/2 Running` durumuna gelip repo (`oytuncan/internshipTasks`) ile bağlantıyı başarıyla kurdu; `maxReplicas: 2` ölçekleme kuralı tanımlandı.

<img width="1221" height="437" alt="Ekran görüntüsü 2026-09-07 153059" src="https://github.com/user-attachments/assets/c588d08d-d85b-4b00-bbe4-ef800ade766f" />


### 6. Repo Yapısı ve CI/CD Pipeline

**`Dockerfile`** (repo kökü):

```dockerfile
FROM bitnami/wordpress:latest

RUN echo "Build: GitOps Automated Pipeline" > /opt/bitnami/wordpress/version.txt
```

**`helm/values.yaml`** (GitOps'un izlediği dosya):

```yaml
image:
  registry: harbor.local
  repository: wordpress/my-wordpress
  tag: latest
  pullPolicy: Always

service:
  type: ClusterIP

mariadb:
  enabled: true
  auth:
    database: bitnami_wordpress
    username: bn_wordpress
    existingSecret: wp-db-secret
    passwordSecretKey: mariadb-password
    rootPasswordSecretKey: mariadb-root-password

existingSecret: wp-db-secret
wordpressUsername: admin
wordpressSecretKey: wordpress-password
```

**`.github/workflows/ci-cd.yaml`** — self-hosted runner üzerinde imajı derler, Harbor'a push'lar ve `values.yaml`'daki tag'i güncelleyip commit atar:

```yaml
name: Build, Push to Harbor and Update GitOps

on:
  push:
    branches:
      - main
    paths-ignore:
      - 'helm/values.yaml'
      - 'README.md'

jobs:
  build-and-deploy:
    runs-on: self-hosted
    steps:
      - name: Check out repository
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Set Image Tag
        id: vars
        run: echo "IMAGE_TAG=sha-${GITHUB_SHA::7}" >> $GITHUB_ENV

      - name: Build Docker Image
        run: |
          docker build -t harbor.local/wordpress/my-wordpress:${{ env.IMAGE_TAG }} .

      - name: Push Docker Image to Harbor
        run: |
          docker push harbor.local/wordpress/my-wordpress:${{ env.IMAGE_TAG }}

      - name: Update Helm values.yaml
        run: |
          sed -i 's|tag:.*|tag: '"${{ env.IMAGE_TAG }}"'|g' helm/values.yaml

      - name: Commit and Push Changes to Git
        run: |
          git config --global user.name "github-actions[bot]"
          git config --global user.email "github-actions[bot]@users.noreply.github.com"
          git add helm/values.yaml
          git commit -m "chore(gitops): update image tag to ${{ env.IMAGE_TAG }} [skip ci]" || echo "No changes to commit"
          git push
```

### 7. Argo CD Application Tanımı

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: wordpress-gitops
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/oytuncan/internshipTasks.git'
    targetRevision: HEAD
    path: helm
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

```bash
kubectl apply -f argocd-wordpress-app.yaml
```

<img width="1893" height="919" alt="Ekran görüntüsü 2026-09-08 134424" src="https://github.com/user-attachments/assets/4d2ace86-54d2-4ef7-b60a-9d08ae5d7a43" />


### 8. Pipeline Zincirinin Özeti

1. **Tetikleme:** `main` dalına kod/ayar push edilir.
2. **Derleme:** Küme içindeki self-hosted runner pod'u kodu çekip `docker build` ile imaj üretir.
3. **Depolama:** Üretilen imaj `harbor.local` adresindeki Harbor'a push'lanır.
4. **Dağıtım:** Argo CD, `helm/values.yaml` dosyasındaki yeni imaj etiketini fark edip WordPress dağıtımını otomatik günceller.
<img width="1877" height="884" alt="Ekran görüntüsü 2026-09-08 130033" src="https://github.com/user-attachments/assets/de4c9877-25bf-4784-ace0-d39b7eca38de" />

### 9. harbor.local için Self-Signed Sertifika

`harbor.local` için gerçek bir self-signed TLS sertifikası üretilip Traefik Ingress kaynağına tanımlandı (HTTP yerine HTTPS erişimi sağlandı).

<!-- Ekran görüntüsü: tarayıcıda harbor.local sertifika bilgisi -->

### 10. Harbor İmaj Saklama Politikası (Retention Policy)

Depolama alanının verimli kullanılması için `wordpress` projesine aşağıdaki kural tanımlandı:

| Ayar | Değer |
|---|---|
| Hedef Proje | `wordpress` |
| Kural Tipi | Gün bazlı saklama (By Days) |
| Kural Süresi | Son 60 gün içinde yüklenen/çekilen imajları koru |
| Depo & Etiket Filtresi | `**` (tüm repo ve etiketler) |
| Untagged Artifacts | Kapsama dahil |
| Çalışma Takvimi | Daily (her gün otomatik) |

<!<img width="1590" height="861" alt="Ekran görüntüsü 2026-09-11 152638" src="https://github.com/user-attachments/assets/d99df29e-38a0-4728-bca8-45b44530921c" />-- Ekran görüntüsü: Harbor retention policy ekranı -->

---

## Notlar

- Bu README, ham çalışma notlarından düzenlenmiştir; ekran görüntüleri (`.jpg`) ilgili adımların altına `<!-- Ekran görüntüsü: ... -->` yorum satırlarının yerine eklenecektir.
- Tüm gerçek parola ve token değerleri placeholder (`<...>`) ile değiştirilmiştir — gerçek değerler yalnızca Kubernetes Secret / güvenli ortam değişkeni olarak saklanmalı, repoya asla commit edilmemelidir.
