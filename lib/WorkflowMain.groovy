//
// This file holds several functions specific to the main.nf workflow in the nf-core/sarek pipeline
//

import nextflow.Nextflow

class WorkflowMain {

    //
    // Citation string for pipeline
    //
    public static String citation(workflow) {
        return "If you use ${workflow.manifest.name} for your analysis please cite:\n\n" +
            "  https://www.biorxiv.org/content/10.1101/2023.08.08.552417v1"

    }

    public void init(params){
      

    }



}