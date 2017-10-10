#! /usr/bin/env node
const spawn = require('cross-spawn');
const split = require('split2');
const fs = require('fs');
const ProgressBar = require('progress');
const mkdirp = require('mkdirp');

const patchesPATH = '../patches';
const processPATH = process.cwd();
const PATH = `${processPATH}/${patchesPATH}`;
mkdirp.sync(PATH);


const gitRevList = spawn.sync('git', ['rev-list', '--count', 'HEAD' ]);
const commitCount = parseInt(gitRevList.stdout.toString());
console.log('git-opensource analyzing:', commitCount, 'commits');
const gitLog = spawn('git', ['log', '-p', '--format=email', '--stat', '--reverse', '--binary']);

let fileCounter = 0;
let fileStream = null;

const progress = new ProgressBar('git-opensource rewrite history: [:bar] :current/:total :percent', { 
  total: commitCount
})

gitLog.stdout
  .pipe(split())
  .on('data', (data)=>{
    const line = data.toString();
    
    if(line.indexOf('From ') === 0) {
      const fileName = ('0000000'+fileCounter++).substr(-8);
      fileStream = fs.createWriteStream(`${PATH}/${fileName}.patch`);
      progress.tick();
    }
    
    fileStream.write(`${line}\n`);

  })

gitLog.on('error', (e)=>{
  console.log('Error', e.toString());
});