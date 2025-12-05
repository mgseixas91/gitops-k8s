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
                    // Criar lista de ambientes novos
                    def num = params.NUM_AMBIENTES.toInteger()
                    def AMBIENTES = (0..<num).collect { "tst${it}" }
                    echo "Ambientes a criar: ${AMBIENTES}"

                    // Listar namespaces existentes
                    def EXISTENTES = sh(script: "kubectl get ns --no-headers -o custom-columns=:metadata.name | grep ^tst || true", returnStdout: true).trim().split("\n").findAll { it }
                    echo "Ambientes existentes: ${EXISTENTES}"

                    // Todos ambientes para criar secret depois
                    env.TODOS_AMBIENTES = (AMBIENTES + EXISTENTES).unique().join(',')
                    echo "Todos ambientes para secret: ${env.TODOS_AMBIENTES}"
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
                    def todos = env.TODOS_AMBIENTES.split(',')
                    for (amb in todos) {
                        def content = """
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
                        def filePath = "${WORKSPACE_CERTS}/san-${amb}.cnf"
                        writeFile file: filePath, text: content
                        echo "Arquivo san.cnf gerado: ${filePath}"
                    }
                }
            }
        }

        stage('Criar ambientes e certificados') {
            steps {
                script {
                    def todos = env.TODOS_AMBIENTES.split(',')
                    for (amb in todos) {
                        echo "Criando/validando ambiente ${amb}"
                        // Criar namespace e AppSet
                        sh "${WORKSPACE_SCRIPTS}/create_env.sh ${amb} ${WORKSPACE_APPS}"
                        sh "${WORKSPACE_SCRIPTS}/create_registry_secret.sh ${amb}"

                        echo "Gerando certificado para ${amb}"
                        def sanFile = "${WORKSPACE_CERTS}/san-${amb}.cnf"
                        // Criar certificados no workspace
                        sh "${WORKSPACE_SCRIPTS}/create_certs.sh ${amb} ${sanFile} ${WORKSPACE_CERTS}"

                        // Criar secret kubernetes com nome correto
                        sh """
                        kubectl create secret generic sqfaas-files \
                            --from-file=sqfaas.jks=${WORKSPACE_CERTS}/sqfaas.jks \
                            --from-file=ca.crt=${WORKSPACE_CERTS}/ca.crt \
                            --namespace=${amb} --dry-run=client -o yaml | kubectl apply -f -
                        """
                        echo "Secret sqfaas-files criada para ${amb}"
                    }
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

