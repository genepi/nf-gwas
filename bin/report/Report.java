
//usr/bin/env jbang "$0" "$@" ; exit $?
//REPOS jcenter,jfrog-genepi-maven=https://genepi.jfrog.io/artifactory/maven/
//DEPS info.picocli:picocli:4.6.1
//DEPS com.github.lukfor:magic-reports:0.1.0

//FILES report.html
//FILES report.css
//FILES phenotypes.html
//FILES phenotypes.js
//FILES logo.svg

import java.io.File;
import java.util.concurrent.Callable;

import picocli.CommandLine;
import picocli.CommandLine.Option;
import lukfor.reports.HtmlReport;

public class Report implements Callable<Integer> {

	@Option(names = "--phenotypes", description = "Phenotypes", required = true)
	private String phenotypes;

	@Option(names = "--files", description = "HTLM Report files", required = true)
	private String input;

	@Option(names = "--project", description = "Project name", required = true)
	private String project;

	@Option(names = "--version", description = "Version", required = true)
	private String version;

	@Option(names = "--output", description = "Output file", required = true)
	private String output;

	public Integer call() throws Exception {

		assert (input != null);
		assert (output != null);

		HtmlReport report = new HtmlReport("");
		report.setMainFilename("report.html");
		report.set("application", "nf-gwas");
		report.set("version", version);
		report.set("project", project);
		report.set("date", "date");
		report.set("phenotypes", phenotypes.split(","));
		report.set("files", input.split(","));
		report.generate(new File(output));

		return 0;
	}

	public static void main(String... args) {
		int exitCode = new CommandLine(new Report()).execute(args);
		System.exit(exitCode);
	}

}
