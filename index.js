const Git = require('nodegit');
const Promise = require('bluebird');

///////////////////////////////////////////////////////////////////////////////
// INPUT

const fromBranch = 'master';
const toBranch = 'test'

///////////////////////////////////////////////////////////////////////////////


console.log("//////////////////////////////////////////////////////////////////////////////////////");
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
          
          return Promise.map(patches, (patch)=>{
            return patch.hunks()
              .then((hunks)=>{     
                console.log('PATCH', patch.newFile().path(), '>', patch.oldFile().path());
                hunks.forEach((hunk)=>{
                  console.log(hunk.header());
                })  
              })
            })
            .then(()=>{
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
                
                
                
                console.log("//////////////////////////////////////////////////////////////////////////");
            });
          

        });
        
        
  
    });

    // Start emitting events.
    history.start();
  });