# nchc service

## DOCKER 安裝
- https://hackmd.io/@whYPD8MBSHWRZV6y-ymFwQ/Hk8pJ95eA
- https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html


## GIT 下載套件
```
git clone https://github.com/wytchen/llmservice
```

## LLaMA Factory Dcoker Image 製作
- 下載套件
```
cd llmservice
mkdir -p storage/source
cd storage/source
git clone https://github.com/hiyouga/LLaMA-Factory.git

```
- 製作映像檔案
```
cd LLaMA-Factory
cp ../../../factory/Dockerfile .
docker build -t factory:latest .
```
- 回到原本路徑
```
cd ../../../
```


## Step 1: 建立 anythingllm_env.txt 及儲存資料夾
- 1. Copy env.sample to .env 
```
cp  env.sample .env 
```
- 2. Edit .env
```
# 登入帳號密
SYSTEM_USER="nchc"
SYSTEM_KEY="nchcservice"

# AnythingLLM儲存位置
STORAGE_DIR="/app/server/storage"

# OPENAI 相容套件金鑰
OPENAI_API_BASE_URLS="https://api.openai.com/v1;https://api.groq.com/openai/v1"
OPENAI_API_KEYS="sk-xxx;gsk_xxx"

# HF_TOKEN
HF_TOKEN="hf_xxx"

```
- 3. Create storage folder
```
mkdir -p storage/anythingllm_data storage/anythingllm_hotdir  storage/anythingllm_outputs storage/ollama_data  storage/openwebui_data  storage/qdrant_data
mkdir -p storage/hf_cache storage/factory_data storage/factory_saves storage/factory_cache storage/jupyter_data
mkdir -p storage/mergekit_tmp
mkdir -p storage/output
cp factory/data/dataset_info.json storage/factory_data/
cp factory/data/identity.json storage/factory_data/
rsync -avHS notebook/ storage/jupyter_data/notebook
rsync -avHS packages/llama.cpp/ storage/jupyter_data/llama.cpp
#chmod 777 storage/anythingllm_data storage/anythingllm_hotdir  storage/anythingllm_outputs
```

## Step 2: (選項) 編輯nginx configure 相關檔案設定單一IP 及供多個HOSTNAME服務 (不一定要處理, 可直接用$IP:$PORT替代)
- folder biobank_ssl (ssl key)
```
privatekey.key
server.cer
```
- nginx configure (同一IP, 不同HOSTNAME)
```
nginx/anythingllm.conf
nginx/default.conf
nginx/ollama.conf
nginx/openwebui.conf
nginx/qdrant.conf
nginx/factory.conf
nginx/llmbook.conf
nginx/llmbook.conf
nginx/mergekit.conf      
```

## Step3: 選擇 basic_ip 或 advanced_ip 或 basic_hostname 或 advanced_hostname 版本
### 選項一: basic_ip 
- 請編修website/index_ds_ip.html, 更換文件中 ${IP} 為你的機器IP, 並開啟 port: 80, 3001, 6333, 8080, 11434)
- 完成後執行以下指令
```
cp compose/docker-compose_basic_ip.yml ./docker-compose.yml
```
### 選項二: advanced_ip 
- 請編修website/index_factory_ip.html, 更換文件中 ${IP} 為你的機器IP, 並開啟 port: 80, 3001, 6333, 7860, 8080, 9999, 11434)
- 完成後執行以下指令
```
cp compose/docker-compose_advanced_ip.yml ./docker-compose.yml
```
### 選項三: basic_hostname 
- 請編修website/index_ds_hostname.html, 依照Step 2的設定, 更換文件中HOSTNAME, 並開啟 port: 443)
- 完成後執行以下指令
```
cp compose/docker-compose_basic_hostname.yml ./docker-compose.yml
```
### 選項四: advanced_hostname 
- 請編修website/index_factory_hostname.html, 依照Step 2的設定, 更換文件中HOSTNAME, 並開啟 port: 443)
- 完成後執行以下指令
```
cp compose/docker-compose_advanced_hostname.yml ./docker-compose.yml
```

## Step 4: 啟動服務
```
docker compose up -d 
```

## Step 5: 關閉服務
```
docker compose down 

#docker compose down -v # 全刪除
```

## Step 6.1: 選項1 (同一IP, 同一PORT, 不同HOSTNAME, 請將以下連結改為你自己的HOSTNAME)
- anythingllm: https://llm.biobank.org.tw
- openwebui: https://openwebui.biobank.org.tw
- ollama api: https://ollama.biobank.org.tw
- qdrant api: https://qdrant.biobank.org.tw
- qdrant dashboard: https://qdrant.biobank.org.tw/dashboard/
- factory: https://factory.biobank.org.tw
- notebook: http://llmbook.biobank.org.tw

## Step 6.2: 選項2 (同一IP, 不同PORT)
- anythingllm: http://$IP:3001
- openwebui: http://$IP:8080
- ollama api: http://$IP:11434
- qdrant api: http://$IP:6333
- qdrant dashboard: http://$IP:6333/dashboard/
- factory: http://$IP:7860
- notebook: http://$IP:9999

## Step7: 內部服務器
- ollama api: http://host.docker.internal:11434
- qdrant api: http://host.docker.internal:6333


## Ollama Template, 記憶體太小請修正 num_ctx=2048
```
FROM ./taide-8b-a.3-q4_k_m.gguf
TEMPLATE """{{ if .System }}<|start_header_id|>system<|end_header_id|>

{{ .System }}<|eot_id|>{{ end }}{{ if .Prompt }}<|start_header_id|>user<|end_header_id|>

{{ .Prompt }}<|eot_id|>{{ end }}<|start_header_id|>assistant<|end_header_id|>

{{ .Response }}<|eot_id|>"""
PARAMETER stop "<|start_header_id|>"
PARAMETER stop "<|end_header_id|>"
PARAMETER stop "<|eot_id|>"
PARAMETER num_keep 24
PARAMETER num_ctx 4096
```

## meragekit 
- That will give you 
- meta-llama/Llama-2-7b-hf + 1.0 * (taide/TAIDE-LX-7B - meta-llama/Llama-2-7b-hf) + 1.0*(meta-llama/Llama-2-7b-chat-hf - meta-llama/Llama-2-7b-hf)
```
merge_method: task_arithmetic
base_model: NousResearch/Llama-2-7b-hf
models:
   - model: taide/TAIDE-LX-7B
     parameters:
        weight: 1.0
   - model: NousResearch/Llama-2-7b-chat-hf
     parameters:
        weight: 1.0
dtype: bfloat16
```

