BEGIN {
	print("run_id,num_pods,num_procs,num_iter,grad_accum,time");
}

// {
	N = split($1, array, "/");
	$1 = array[N];

	split($1, array, "_");
	for(elem in array) {
          if(index(array[elem], "npods")>0) {
                split(array[elem], subarray, "npods");
                num_pods = subarray[2];
          }

	  if(index(array[elem], "nprocs")>0) {
                split(array[elem], subarray, "nprocs");
                num_procs = subarray[2];
          }
		
      
          if(index(array[elem], "numiter")>0) {
		split(array[elem], subarray, "numiter");
      		num_iter = subarray[2];		
	  }

	  if(index(array[elem], "gradaccum")>0) {
	  	split(array[elem], subarray, "gradaccum");
		grad_accum = subarray[2];
	  }

	  if(index(array[elem], "runid")>0) {
                split(array[elem], subarray, "runid");
                run_id = subarray[2];
		split(run_id, array, ".");
		run_id = array[1];
          }
	 
	}
	time = $2;
	print(run_id","num_pods","num_procs","num_iter","grad_accum","time);
}

function extract(snippet, search) {
  if(index(snippet, search)>0) {
  	split(snippet, array, search);
	return array[2];
  }	
}

END {
}
