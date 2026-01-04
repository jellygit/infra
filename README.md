# 금융 서비스 인프라 자동화 (Financial Services Infrastructure Automation)

이 저장소는 금융 서비스 환경을 위해 설계된 **Infrastructure as Code (IaC)** 코드를 포함하고 있으며, 안전하고 고가용성을 갖춘 인프라를 배포하는 것을 목표로 합니다. Ansible을 사용하여 자동화를 구현했으며, HashiCorp Vault를 통한 비밀 관리 및 Keepalived를 이용한 고가용성(High Availability) 구성을 포함합니다.

## 🌟 주요 기능 (Key Features)

- **중앙화된 설정 관리**: 모든 서버 IP와 도메인은 `group_vars/all.yml`에서 중앙 관리되므로, 환경 마이그레이션(예: IDC에서 클라우드로 이동) 작업이 원활합니다.
- **고가용성 (HA)**: Keepalived를 이용한 가상 IP(VIP) 관리 기능을 포함하여 Vault 클러스터를 배포함으로써 지속적인 서비스 가용성을 보장합니다.
- **보안 우선 (Security First)**:
  - TLS 인증서 자동 생성(Self-signed Root CA) 및 배포.
  - OS 보안 강화(Hardening) 및 Firewalld 설정 기본 포함.
  - 엄격한 NFS export 제어.
- **멱등성 (Idempotency)**: 플레이북은 반복 실행에도 안전하도록 설계되었습니다 (예: Etckeeper 커밋 처리, CA 신뢰 업데이트 등).

## 📋 사전 요구 사항 (Prerequisites)

- **컨트롤 노드 (Control Node)**:
  - Python 3.13 이상
  - Ansible (Core)
  - `hvac` 라이브러리 (Vault 연동용)
- **타겟 노드 (Target Nodes)**:
  - RHEL 9/10, AlmaLinux, 또는 Rocky Linux.
  - sudo 권한이 있는 SSH 접근 계정.

## 🚀 시작하기 (Getting Started)

### 1. 환경 설정 (Configuration)

인벤토리와 전역 변수를 사용자의 환경에 맞게 수정하십시오.

- **인벤토리**: `inventory/hosts` 파일을 편집하여 `vault_cluster`, `backup`, 및 기타 노드 그룹을 정의합니다.
- **변수**: `inventory/group_vars/all.yml` 파일에서 IP와 도메인 정보를 설정합니다.

  ```yaml
  infra_ips:
    vault_srv: "192.168.1.10"
    backup_srv: "192.168.1.20"
  
  infra_domains:
    vault: "vault.infra.lan"
    backup: "backup.infra.lan"
  ```

### 2. 플레이북 실행 (Run Playbooks)

배포 과정은 모듈화된 플레이북으로 나뉘어 있습니다. 다음 순서대로 실행하십시오.

#### 단계 1: 기본 설정 및 인증서 생성

내부 CA를 생성하고 모든 노드에 신뢰 앵커(Trust Anchor)를 배포합니다.

```bash
# 로컬에서 CA 및 인증서를 생성한 후, 노드에 기본 패키지 및 CA 신뢰 설정 설치
ansible-playbook setup-infra-base.yml
```

#### 단계 2: 스토리지 설정

중앙 백업 서버(NFS)를 구성합니다.

```bash
ansible-playbook setup-storage.yml
```

#### 단계 3: Vault 클러스터 배포

Keepalived 및 TLS가 적용된 Vault 클러스터를 배포합니다.

```bash
# 이 플레이북은 인증서 생성(아직 안 된 경우) 및 클러스터 구성을 처리합니다
ansible-playbook site.yml
```

#### 단계 4: 재해 복구 (선택 사항)

백업 및 DR(Disaster Recovery) 워크플로우를 설정합니다.

```bash
ansible-playbook setup-backup-dr.yml
```

## 📂 프로젝트 구조 (Project Structure)

```text
.
├── certs/                  # 생성된 인증서 (CA, Keys, CSRs)
├── inventory/              # Ansible 인벤토리 및 그룹 변수
│   ├── hosts               # 인벤토리 파일
│   └── group_vars/         # 전역 변수 (IPs, Domains)
├── templates/              # 설정 파일용 Jinja2 템플릿
│   ├── vault.hcl.j2        # Vault 설정
│   └── keepalived.conf.j2  # Keepalived HA 설정
├── site.yml                # Vault 클러스터용 메인 플레이북
├── setup-infra-base.yml    # 기본 OS 설정 및 CA 신뢰 배포
├── setup-storage.yml       # NFS 스토리지 구성
└── setup-os-hardening.yml  # 보안 강화(Hardening) 규칙
```

## ⚠️ 마이그레이션 가이드 (IDC to Cloud)

새로운 환경으로 마이그레이션하려면:

1. `inventory/hosts` 파일을 새로운 서버 주소로 업데이트하십시오.
2. `inventory/group_vars/all.yml` 파일의 `infra_ips` 섹션에서 새로운 IP 매핑을 업데이트하십시오.
3. `setup-infra-base.yml`부터 플레이북을 다시 순차적으로 실행하십시오.
