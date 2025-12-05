pipeline {
    agent any

    parameters {
        string(name: 'NUM_AMBIENTES', defaultValue: '2', description: 'Número de ambientes a criar')
    }

    environment {
        WORKSPACE_SCRIPTS = "${env.WORKSPACE}/gitops-envs/scripts"
        WORKSPACE_APPS    = "${env.WORKSPACE}/gitops-apps/apps"
        KUBECONFIG        = "/var/lib/jenkins/.kube/config"  // Certifique-se de que está configurado com token longo
    }

    stages {

        stage('Preparar ambientes') {
            steps {
                script {
                    int num = params.NUM_AMBIENTES.toInteger()
                    def existentes = sh(script: "kubectl get ns -o jsonpath='{.items[*].metadata.name}'", returnStdout: true)
                                      .trim().split(/\s+/)
                    
                    // Descobre o próximo índice disponível
                    int nextIndex = 0
                    while (existentes.contains("tst${nextIndex}")) { nextIndex++ }

                    // Gera lista de ambientes a criar
                    AMBIENTES = (0..<num).collect { "tst${it + nextIndex}" }
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

        stage('Criar ambientes') {
            steps {
                script {
                    for (amb in AMBIENTES) {
                        echo "Criando ambiente ${amb}"
                        sh "${WORKSPACE_SCRIPTS}/create_env.sh ${amb} ${WORKSPACE_APPS}"
                        sh "${WORKSPACE_SCRIPTS}/create_registry_secret.sh ${amb}"
                    }

                    // Atualiza secrets nos ambientes existentes também
                    echo "Atualizando secrets nos ambientes existentes..."
                    def existentes = sh(script: "kubectl get ns -o jsonpath='{.items[*].metadata.name}'", returnStdout: true)
                                      .trim().split(/\s+/)
                    for (ns in existentes) {
                        if (ns.startsWith("tst") && !AMBIENTES.contains(ns)) {
                            echo "Atualizando secret acr-secret no namespace ${ns}"
                            sh "${WORKSPACE_SCRIPTS}/create_registry_secret.sh ${ns}"
                        }
                    }

                    input message: 'Ambientes criados e secrets atualizadas. Confirmar para prosseguir?', ok: 'Sim'
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

