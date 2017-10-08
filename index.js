const Git = require('nodegit');


///////////////////////////////////////////////////////////////////////////////
// INPUT

const fromBranch = 'master';
const toBranch = 'test'

///////////////////////////////////////////////////////////////////////////////

Git.Repository.open('./')
  .then((repo)=>repo.getBranchCommit(fromBranch))
  .then(function(firstCommitOnMaster) {
    // Create a new history event emitter.
    var history = firstCommitOnMaster.history();

    // Create a counter to only show up to 9 entries.
    var count = 0;

    // Listen for commit events from the history.
    history.on("commit", function(commit) {
      
      commit.getDiff()
        .then((diff)=>diff[0].patches())
        .then((patches)=>{
          
          
          // Show the commit sha.
          console.log("commit " + commit.sha());
    
          // Store the author object.
          var author = commit.author();
    
          // Display author information.
          console.log("Author:\t" + author.name() + " <" + author.email() + ">");
    
          // Show the commit date.
          console.log("Date:\t" + commit.date());
    
          // Give some space and show the message.
          console.log("\n    " + commit.message());  
          
          patches.forEach((patch)=>console.log(patch.newFile().path(), patch.oldFile().path()));
          
          return patches[0].hunks().then((hunks)=>{
            console.log('header', hunks[0].header());
            console.log('header length', hunks[0].headerLen());
            console.log('new lines', hunks[0].newLines());
            console.log('new start', hunks[0].newStart());
            console.log('old lines', hunks[0].oldLines());
            console.log('old start', hunks[0].oldStart());
          })
          
        });
        
        
  
    });

    // Start emitting events.
    history.start();
  });