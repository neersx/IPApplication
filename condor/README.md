# Inprotech Kaizen
## Build
### Prerequisites
* NodeJS [download](http://nodejs.org/download/)
* [NVM](https://github.com/coreybutler/nvm-windows/releases) - for multi-targeted node environment
 
All of the commands below should be run in condor directory (i.e. where this file is).

### Initial setup
* Install gulp-cli ```npm install -g gulp-cli```
* Install @angular-cli ```npm install -g @angular-cli```

**Note :** Instead of installing the packages globally, you can also run them locally from the condor folder using npx

```npx gulp serve```

```npx ng lint```

***

### Checkout the branch you wish to work on
* For example to work on vnext branch: ```git checkout vnext```

### Downloading dependencies
Run following commands to download dependencies used by build process and the application.
This step is required during first setup and **everytime packages.json file has been changed**.

* Install node dependencies ```npm install```
    ##### Updating Design Guide dependency
    If you have pushed changes to design guide. You must push the updated packages-lock.json file
    *  Install node dependencies ```npm install designguide```

### Run in debug mode
```gulp serve ```

# Gulp Commands
Following is a list of gulp commands and options available, you can also check these by runing ```gulp -T``` in condor folder

| Command   | --Option  | Description   | Example   |
| -------   | --------  | -----------   | -------   |
| **serve** |           | Run App in debug mode    | ```gulp serve```  |
|           | realapi   | Connects with a debug instance of backend API | ```gulp serve --realapi```    |
|           | hybrid    | Real time deployment to server/debug folder along with the e2e test pages. This process works only if the command prompt has administrative privileges. | ```gulp serve --hybrid```    |
|           | headless  | Stop automatic opening of browser tab after serve completes | ```gulp serve --headless --realapi```   |
| **test**  |           | Builds the AngularJs Application and Tests both AngularJs and Angular Tests | ```gulp test```
|           | nobuild   | Does **not** build the application, runs both AngularJs and Angular Test. Usefull for when you have made changes to spec files only and dont want to rebuild the application again | ```gulp test --nobuild```    |
|           | ngonly    | Does **not** build the application, runs Jest tests only for Angular |  ```gulp test --ngonly```  |
|           | ngjsonly    | Does **not** run jest tests, runs tests only for AngularJs |  ```gulp test --ngonly``` or ```gulp test --nobuild --ngonly```  |
|           | coverage    | Runs the coverage report for all the tests. |  ```gulp test --coverage```  |
|           | jestworkers | Number of workers to spawn for jest testing. Default: Number of Cores(including HT) - 1 | ```gulp test --jestworkers=2``` or ```gulp test --ngonly --jestworkers=2 ``` |
|           | teamcity  | sets the test reporters to Teamcity, if jest worker option is not provided, sets it to 2 | ```gulp test --teamcity``` or ```gulp test --teamcity --jestworkers=3```|
|           | coverage  | generate combined coverage report for both angularjs and angular, to access report, open condor/client/index.html   | ```gulp test --coverage``` |
| **lint**      |                   | Lints, Js, TS and Angular TS files    | ```gulp lint``` |
| **vsdeploy**  |                   | Builds and deploys the client folder to Inprotech.Server's bin>Debug folder   | ```gulp vsdeploy``` |
|               | includeBatchEvent | Copies batch event update, usefull if you want to test something in Batch Event Update | ```gulp vsdeploy --includeBatchEvent=true``` |
|               | gzCompress        | By default false. Set to true for enabling Gzip compression for ng and condor build files | ```gulp vsdeploy --gzCompress=true``` |
| **vsrelease** |                   | Builds and deploys the client folder to Inprotech.Server's bin>release folder | ```gulp vsrelease``` |
|               | includeBatchEvent | Copies batch event update, usefull if you want to test something in Batch Event Update |
|               | gzCompress        | Gzip compression enabled for compressing ng and condor build files |
| **build**     |                   | Create a build of the app in .dist    | ```gulp build```      |
|               | debug             | Creates source maps to aid debugging  | **To be verified**    |
|               | includeBatchEvent | Same as above             |                       |
|               | includeE2e        | By default false. Set to true for including dev pages | ```gulp build --includeE2e=true``` |
|               | gzCompress        | By default false. Set to true for enabling Gzip compression for ng and condor build files | ```gulp build --gzCompress=true``` |
| **deploy**    |                   | Deploys ./dist folder |   ```gulp dist``` |
|               | vsdebug           | Copy to Inprotech.Server Debug folder     | ```gulp dist --vsdebug``` |
|               | vsrelease         | Copy to Inprotech.Server Release folder   | ```gulp dist --vsrelease``` |
|               | path              | Any other Path to deploy to               |   |



## NPM Scripts
NPM scripts are shortcuts for running long script commands, these scripts are availbale in scrips section of package.json and can be run using command ```npm run [scriptName]```
Some commonly used are

| Run                       | Description   |
| -------                   | ---------     |
| ```npm run clearnode```   | Clears the Node_module folder. It is faster then deleting the folder using Windows Explorer. Note: At end of the execution you will get an error as the package that deletes the folder is removed itself |
| ```npm run lint:ng```     | Calls ng lint with verbose option |
| ```npm start```           | Calls gulp serve with --reapapi parameter |
| ```npm build:ng```        | Builds Angular Project and deploys it to tmp folder, same as gulp serve |