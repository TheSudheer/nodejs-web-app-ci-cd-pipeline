This repository contains the `Jenkinsfile` and associated configuration for a Continuous Integration and Continuous Deployment (CI/CD) pipeline. The pipeline automates the process of testing a React.js application, building a Docker image, pushing it to Docker Hub, and deploying it to an AWS EC2 instance.

**Objective:** To demonstrate a functional CI/CD workflow suitable for modern web application development and deployment.

## Proof of Execution (Screenshots)

*(As requested for the interview task, here are the proofs of a successful pipeline execution and the running application.)*

**1. Jenkins Build Success:**

*Description: This screenshot shows the Jenkins pipeline view, indicating all stages (Test, Docker Build, Push to DockerHub, Deploy to EC2-Server) completed successfully.*

```markdown
![Jenkins Build Success](/home/sudheer/nodejs-web-app-ci-cd-pipeline/screenshots/jenkins_success_screenshot.png)
```

**2. Running Web Application on EC2:**

*Description: This screenshot shows the React application successfully running and accessible via a web browser, served from the EC2 instance on port 3080.*

```markdown
![Running Web Application on EC2](/home/sudheer/nodejs-web-app-ci-cd-pipeline/screenshots/webapp_running_screenshot.png)
---

## Prerequisites

Before running this pipeline, ensure the following are set up:

1.  **Jenkins Server:** A running Jenkins instance.
2.  **Jenkins Plugins:**
    * Pipeline
    * Docker Pipeline (or Docker plugin)
    * Credentials Binding
    * SSH Agent
    * Git (if pulling `Jenkinsfile` from SCM)
3.  **Jenkins Agent Configuration:**
    * The Jenkins agent (`agent any` implies any available agent) must have Docker installed and running.
    * The Jenkins agent must have Node.js and npm installed to run the tests (`npm test`).
    * The user running the Jenkins agent process must have permissions to execute Docker commands.
4.  **Source Code:** The React.js application source code, including:
    * `package.json` with test scripts defined.
    * A `Dockerfile` in the root directory to build the application image.
5.  **Docker Hub Account:** A Docker Hub account to push the image to.
6.  **AWS EC2 Instance:**
    * An EC2 instance running a Linux distribution (like Ubuntu).
    * Docker installed and running on the EC2 instance.
    * The EC2 instance's security group must allow inbound traffic on port 3080 (or the port your application uses) and port 22 (for SSH).
7.  **Jenkins Credentials:**
    * `docker-hub-credentials`: Jenkins Username/Password credential type containing your Docker Hub username and password (or access token).
    * `ec2-server-key`: Jenkins SSH Username with private key credential type containing the private key for SSH access to the EC2 instance, associated with the `ubuntu` user (or the user configured on your EC2).

---

## Pipeline Overview

The `Jenkinsfile` defines a declarative pipeline with the following key components:

1.  **Parameters:**
    * `DEPLOY_ENV`: A string parameter to potentially specify the deployment environment (e.g., 'dev', 'staging', 'prod'). Default value is 'dev'. *Note: This parameter is defined but not explicitly used in the deployment logic of the provided stages.*

2.  **Environment Variables:**
    * `IMAGE_TAG`: Set to the Jenkins build number (`${env.BUILD_NUMBER}`) for unique image tagging.
    * `imageName`: Constructs the full Docker image name: `kalki2878/react-js-app:${env.BUILD_NUMBER}`.

3.  **Stages:** The pipeline executes the following stages sequentially:
    * **`test`**:
        * Prints a message indicating testing is starting.
        * Executes `npm test` within the project directory.
        * `CI=true` is often used to signal to testing frameworks that they are running in a non-interactive CI environment.
        * `|| true` is appended to the command. **Important:** This means the pipeline stage will be marked as successful *even if the tests fail*. This might be useful for demonstration but should typically be removed in a production pipeline to enforce passing tests.
    * **`Docker Build`**:
        * Builds a Docker image using the `Dockerfile` located in the workspace root (`.`).
        * Tags the image with the `imageName` defined in the environment block (e.g., `kalki2878/react-js-app:5`).
    * **`Push to DockerHub Registry`**:
        * Uses the `withCredentials` step to securely inject Docker Hub credentials (`docker-hub-credentials`) into environment variables (`DOCKER_USERNAME`, `DOCKER_PASSWORD`).
        * Logs in to Docker Hub using the injected credentials.
        * Pushes the previously built Docker image (`${imageName}`) to the Docker Hub repository.
    * **`Deploy to EC2-Server`**:
        * Uses the `sshagent` step with the `ec2-server-key` credential to securely establish an SSH connection to the target EC2 instance.
        * Connects to `ubuntu@18.142.239.7`. `-o StrictHostKeyChecking=no` is used to automatically accept the host key (use with caution, ideally manage known hosts).
        * Executes commands remotely on the EC2 instance:
            * `docker pull ${imageName}`: Pulls the latest version of the image just pushed to Docker Hub.
            * `docker run -d --name myapp -p 3080:3080 ${imageName}`: Runs the pulled image as a detached container (`-d`), names it `myapp`, and maps port 3080 on the EC2 host to port 3080 in the container. **Note:** This command doesn't stop or remove any existing container named `myapp`. If a container with that name already exists, this step will fail. A more robust deployment would involve stopping and removing the old container before starting the new one.
        * Prints a deployment message.

4.  **Post Actions:**
    * `always`: This block runs regardless of the pipeline's success or failure.
    * `archiveArtifacts`: Attempts to archive any files matching `**/test-results/**` or `**/logs/**`. `allowEmptyArchive: true` ensures the build doesn't fail if no such files are found.

---

## How to Run

1.  Ensure all prerequisites are met.
2.  Create a new Pipeline job in Jenkins.
3.  Configure the job:
    * In the "Pipeline" section, select "Pipeline script from SCM".
    * Choose your SCM (e.g., Git).
    * Provide the repository URL where your code (including the `Jenkinsfile`) resides.
    * Specify the branch (e.g., `main` or `master`).
    * Ensure the "Script Path" is set to `Jenkinsfile` (this is usually the default).
    * *(Alternatively, for testing, you can select "Pipeline script" and paste the content of the `Jenkinsfile` directly into the text area.)*
4.  Save the Jenkins job configuration.
5.  Click "Build Now" (or "Build with Parameters" if you want to potentially change `DEPLOY_ENV`, though it's not used here).
6.  Observe the pipeline execution through the Jenkins UI (Blue Ocean or the standard stage view).

---
