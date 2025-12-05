pipeline {
    agent any

    parameters {
        string(name: 'NUM_AMBIENTES', defaultValue: '2', description: 'Número de ambientes a criar')
    }

    environment {
        WORKSPACE_SCRIPTS = "${env.WORKSPACE}/gitops-envs/scripts"
        WORKSPACE_APPS    = "${env.WORKSPACE}/gitops-apps/apps"
        WORKSPACE_CERTS   = "${env.WORKSPACE}/certs"
    }

    stages {

        stage('Preparar ambientes') {
            steps {
                script {
                    int num = params.NUM_AMBIENTES.toInteger()
                    // Se AMBIENTES já existir, cria os próximos índices
                    def existing = sh(script: "kubectl get ns --no-headers -o custom-columns=:metadata.name | grep '^tst' || true", returnStdout: true).trim().split("\n").findAll{ it }
                    int start = existing ? existing.collect{ it.replaceAll('tst','').toInteger() }.max() + 1 : 0
                    AMBIENTES = (start..<start+num).collect { "tst${it}" }
                    echo "Ambientes a criar: ${AMBIENTES}"
                }
            }
        }

        stage('Verificar scripts') {
            steps {
                sh "chmod +x ${WORKSPACE_SCRIPTS}/*.sh"
                sh "ls -l ${WORKSPACE_APPS}"
            }
        }

        stage('Gerar san.cnf dinamicamente') {
            steps {
                script {
                    AMBIENTES.each { amb ->
                        def sanFile = "${WORKSPACE_CERTS}/san-${amb}.cnf"
                        writeFile file: sanFile, text: """
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = *.sqfaas.dev

[v3_req]
keyUsage = critical, digitalSignature, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = kc.${amb}.sqfaas.dev
DNS.2 = ${amb}.sqfaas.dev
DNS.3 = bff.${amb}.sqfaas.dev
DNS.4 = k8s.${amb}.sqfaas.dev
DNS.5 = config.${amb}.sqfaas.dev
DNS.6 = sqctrl.${amb}.sqfaas.dev
DNS.7 = sqctrlportal.${amb}.sqfaas.dev
DNS.8 = kc9.${amb}.sqfaas.dev
DNS.9 = portalbff.${amb}.sqfaas.dev
DNS.10 = portal.${amb}.sqfaas.dev
DNS.11 = tomcat.${amb}.sqfaas.dev
"""
                        echo "Arquivo san.cnf gerado para ${amb}: ${sanFile}"
                    }
                }
            }
        }

        stage('Criar ambientes e certificados') {
            steps {
                script {
                    for (amb in AMBIENTES) {
                        echo "Criando ambiente ${amb}"
                        sh "${WORKSPACE_SCRIPTS}/create_env.sh ${amb} ${WORKSPACE_APPS}"
                        sh "${WORKSPACE_SCRIPTS}/create_registry_secret.sh ${amb}"
                        sh "${WORKSPACE_SCRIPTS}/create_certs.sh ${amb} ${WORKSPACE_CERTS}/san-${amb}.cnf ${WORKSPACE_CERTS}"
                    }

                    input message: 'Ambientes criados e certificados gerados. Confirmar para prosseguir?', ok: 'Sim'
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finalizada"
        }
    }
}

