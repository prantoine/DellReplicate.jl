var documenterSearchIndex = {"docs":
[{"location":"mathias/#THIS-IS-A-SECOND-TEST","page":"THIS IS A SECOND TEST","title":"THIS IS A SECOND TEST","text":"","category":"section"},{"location":"mathias/","page":"THIS IS A SECOND TEST","title":"THIS IS A SECOND TEST","text":"Is this working ?","category":"page"},{"location":"figure1/","page":"Figure 1","title":"Figure 1","text":"CurrentModule = DellReplicate","category":"page"},{"location":"figure1/#Figure-1-functions","page":"Figure 1","title":"Figure 1 functions","text":"","category":"section"},{"location":"figure1/","page":"Figure 1","title":"Figure 1","text":"This page contains the functions used to generate Figure 1 of Dell (2012).","category":"page"},{"location":"figure1/","page":"Figure 1","title":"Figure 1","text":"","category":"page"},{"location":"figure1/","page":"Figure 1","title":"Figure 1","text":"figure1_visualise\nfigure1_data_cleaner\nread_csv\ngen_vars_fig1!","category":"page"},{"location":"figure1/#DellReplicate.figure1_visualise","page":"Figure 1","title":"DellReplicate.figure1_visualise","text":"figure1_visualise(df::String)\n\nPlots Figure 1 from Dell (2012) by calling the data cleaning function figure1_data_cleaner with the climate_panel_csv.csv dataset.\n\n\n\n\n\n","category":"function"},{"location":"figure1/#DellReplicate.figure1_data_cleaner","page":"Figure 1","title":"DellReplicate.figure1_data_cleaner","text":"figure1_data_cleaner()\n\nLoads the climate_panel_csv dataset and reproduces Dell's (2012) makefigure1.do commands. Returns a DataFrame object which can be used by ???\n\n\n\n\n\n","category":"function"},{"location":"figure1/#DellReplicate.read_csv","page":"Figure 1","title":"DellReplicate.read_csv","text":"read_csv(fn::String)\n\nCreates a DataFrame object from a .csv file, where fn is the file name. May only work if ran from a directory where assets if is in the same parent directory. \n\n\n\n\n\n","category":"function"},{"location":"figure1/#DellReplicate.gen_vars_fig1!","page":"Figure 1","title":"DellReplicate.gen_vars_fig1!","text":"gen_vars_fig1!(df::DataFrame)\n\nGenerates the necessary mean temperature and precipiation variables for the two graphs of Figure 1, given the climate panel data. Returns the modified version of input df.\n\n\n\n\n\n","category":"function"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = DellReplicate","category":"page"},{"location":"#DellReplicate.jl","page":"Home","title":"DellReplicate.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for DellReplicate.","category":"page"}]
}
