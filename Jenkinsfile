pipeline {
    agent {
        kubernetes {
            label 'jenkins-agent-k8s'
            defaultContainer 'jnlp'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: jenkins-agent-k8s
spec:
  containers:
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
  - name: maven
    image: maven:3.9.2-openjdk-17
    command:
    - cat
    tty: true
"""
        }
    }
    environment {
        GITOPS_SCRIPTS = 'gitops-envs/scripts'
        GITOPS_APPS    = 'gitops-apps/apps'
    }
    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Preparar ambientes') {
            steps {
                script {
                    // Pergunta ao usuário quantos ambientes criar
                    def envCount = input(
                        id: 'envCountInput', message: 'Quantos ambientes deseja criar?', parameters: [
                            string(defaultValue: '1', description: 'Número de ambientes', name: 'NUM_ENV')
                        ]
                    )
                    // Gera a lista de ambientes
                    ENV_NAMES = (1..envCount.NUM_ENV.toInteger()).collect { "tst${it-1}" }
                    echo "Ambientes a criar: ${ENV_NAMES}"
                }
            }
        }

        stage('Criar ambientes') {
            steps {
                script {
                    for (env in ENV_NAMES) {
                        echo "Criando ambiente ${env}..."
                        container('kubectl') {
                            sh "${GITOPS_SCRIPTS}/create_env.sh ${env} ${GITOPS_APPS}"
                        }
                        // Pergunta ao usuário se deseja prosseguir
                        def continueTests = input(
                            id: "continue-${env}", message: "Ambiente ${env} criado. Deseja rodar os testes?", parameters: [
                                booleanParam(defaultValue: true, description: 'Clique em Sim para continuar', name: 'CONTINUE')
                            ]
                        )
                        if (!continueTests.CONTINUE) {
                            error("Pipeline interrompida pelo usuário")
                        }
                    }
                }
            }
        }

        stage('Executar testes') {
            steps {
                script {
                    for (env in ENV_NAMES) {
                        echo "Rodando testes para ambiente ${env}..."
                        container('maven') {
                            sh "${GITOPS_SCRIPTS}/run_tests.sh ${env}"
                        }
                        def testContinue = input(
                            id: "test-${env}", message: "Testes do ambiente ${env} concluídos. Deseja destruir o ambiente?", parameters: [
                                booleanParam(defaultValue: true, description: 'Sim para destruir, Não para manter', name: 'DESTROY')
                            ]
                        )
                        if (testContinue.DESTROY) {
                            echo "Destruindo ambiente ${env}..."
                            container('kubectl') {
                                sh "${GITOPS_SCRIPTS}/destroy_env.sh ${env} ${GITOPS_APPS}"
                            }
                        } else {
                            echo "Ambiente ${env} será mantido."
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            echo "Pipeline finalizada."
        }
    }
}

