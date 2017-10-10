const spawn = require('cross-spawn');
const split = require('split2');
const fs = require('fs');
const ProgressBar = require('progress');

const PATH = './patches';

const gitRevList = spawn.sync('git', ['rev-list', '--count', 'HEAD' ]);
const gitLog = spawn('git', ['log', '-p', '--format=email', '--full-diff', '--stat']);

let fileCounter = 0;
let fileStream = null;

const progress = new ProgressBar('git-opensource [:bar] :current/:total :percent :etas', { 
  total: parseInt(gitRevList.stdout.toString())
})

gitLog.stdout
  .pipe(split())
  .on('data', (data)=>{
    const line = data.toString();
    
    if(line.indexOf('From ') === 0) {
      const fileName = ('00000'+fileCounter++).split(-5);
      fileStream = fs.createWriteStream(`${__dirname}/${PATH}/${fileName}.patch`);
      progress.tick();
    }
    
    fileStream.write(`${line}\n`);

  })

gitLog.on('error', (e)=>{
  console.log('Error', e.toString());
});