pipeline {
    agent any

    // Fires automatically when GitHub sends the push webhook
    triggers { githubPush() }

    environment {
        STUDENT_ID = 'SP23-BAI-004'
        IMAGE      = 'midterm-sp23-bai-004'
        CONTAINER  = 'midterm-app'
        INSTRUCTOR = 'qasimalik@gmail.com'
        SENDER     = 'amnaaahmadh@gmail.com'   // <-- CHANGE to the Gmail you submit in the Google Form
    }

    options {
        timeout(time: 15, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {
        stage('Fetch Latest Data') {
            steps {
                checkout scm
                sh 'git log -1 --oneline'
                sh 'wc -l dataset/train.csv'
            }
        }

        stage('Setup Python') {
            steps {
                sh '''
                    python3 -m venv .venv
                    . .venv/bin/activate
                    pip install -q --upgrade pip
                    pip install -q -r requirements.txt pytest httpx
                '''
            }
        }

        stage('Retrain Model') {
            steps {
                // train.py reads GIT_COMMIT (set by Jenkins) into metrics.git_sha
                sh '''
                    . .venv/bin/activate
                    python train.py
                    cat artifacts/metrics.json
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    . .venv/bin/activate
                    python -m pytest -v tests/
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t ${IMAGE}:${BUILD_NUMBER} -t ${IMAGE}:latest .'
            }
        }

        stage('Deploy on EC2') {
            steps {
                sh '''
                    docker rm -f ${CONTAINER} || true
                    docker run -d --name ${CONTAINER} --restart unless-stopped \
                        -p 8000:8000 ${IMAGE}:latest
                    # wait until the new container answers
                    for i in $(seq 1 20); do
                        if curl -sf http://localhost:8000/metrics; then echo; echo "DEPLOYED"; exit 0; fi
                        sleep 2
                    done
                    echo "Container did not become healthy"; docker logs ${CONTAINER}; exit 1
                '''
                // remove old images so the disk does not fill up
                sh 'docker image prune -f || true'
            }
        }
    }

    post {
        always {
            script {
                def m = fileExists('artifacts/metrics.json') ? readFile('artifacts/metrics.json') : 'metrics not generated'
                emailext(
                    to: "${INSTRUCTOR}",
                    from: "${SENDER}",
                    subject: "SP23-BAI-004 | MIDTERM-SP23-BAI-004 Build #${BUILD_NUMBER} - ${currentBuild.currentResult}",
                    mimeType: 'text/plain',
                    body: """Student Reg No: SP23-BAI-004
Student Name: Amna Ahmad
Job: ${JOB_NAME}  Build: #${BUILD_NUMBER}
Result: ${currentBuild.currentResult}
Commit: ${env.GIT_COMMIT}
Build URL: ${BUILD_URL}

Model metrics:
${m}
"""
                )
            }
        }
    }
}
