//usr/bin/env jbang "$0" "$@" ; exit $?
//REPOS jcenter,jfrog-genepi-maven=https://genepi.jfrog.io/artifactory/maven/
//DEPS info.picocli:picocli:4.6.1
//DEPS genepi:genepi-io:1.1.1

import java.io.File;
import java.util.List;
import java.util.Scanner;
import java.util.concurrent.Callable;
import genepi.io.table.writer.CsvTableWriter;
import picocli.CommandLine;
import picocli.CommandLine.Option;
import picocli.CommandLine.Parameters;

public class RegenieLogParser implements Callable<Integer> {

	private static String REGENIE_CALL_PATTERN = "Options in effect:";

	@Parameters(description = "Regenie log file")
	private List<String> files;

	@Option(names = "--output", description = "Output file ", required = true)
	private String output;

	public void setOutput(String output) {
		this.output = output;
	}

	public Integer call() throws Exception {

		assert (files != null);
		assert (output != null);

		CsvTableWriter writer = new CsvTableWriter(new File(output).getAbsolutePath(), '\t', false);

		String[] columnsWrite = { "Name", "Value" };
		writer.setColumns(columnsWrite);

		StringBuilder warningMsgs = new StringBuilder();
		StringBuilder optionsInEffect = new StringBuilder();

		int countVariants = 0;
		int countFiles = 0;

		for (String file : files) {

			countFiles++;

			boolean isRegenieCall = false;
			Scanner s = new Scanner(new File(file));

			while (s.hasNextLine()) {

				String line = s.nextLine();

				// identify regenie call line and skip it
				if (line.contains(REGENIE_CALL_PATTERN)) {
					isRegenieCall = true;
					continue;
				}

				if (line.contains("-summary : bgen file")) {
					String value = line.split("\\s+")[14].trim();
					countVariants += Integer.valueOf(value);
				} else if (line.contains("n_snps") && line.contains("pvar")) {
					String value = line.split("=")[1].trim();
					countVariants += Integer.valueOf(value);
				} else if (line.contains("WARNING:")) {
					warningMsgs.append(line + "\n");
				}

				// Several log files produced (step 1+2), therefore skip everything from here.
				if (countFiles > 1) {
					continue;
				}

				// parse all lines with regenie option included
				if (isRegenieCall) {
					if (!line.endsWith("\\")) {
						isRegenieCall = false;
					} else {
						optionsInEffect.append(line.substring(0, line.indexOf('\\')));
					}
				}

				if (line.contains("REGENIE v")) {
					String value = line.split("\\s+")[3].trim();
					writer.setString(0, "Regenie Version ");
					writer.setString(1, value);
					writer.next();
				} else if (line.contains("n_snps") && line.contains("bim")) {
					String value = line.split("=")[1].trim();
					writer.setString(0, "Variants total (*.bim)");
					writer.setInteger(1, Integer.valueOf(value));
					writer.next();
				} else if (line.contains("+number of variants remaining in the analysis")) {
					String value = line.split("=")[1].trim();
					writer.setString(0, "Variants used (*.bim)");
					writer.setInteger(1, Integer.valueOf(value));
					writer.next();
				} else if (line.contains("+number of genotyped individuals to keep")) {
					String value = line.split("=")[1].trim();
					writer.setString(0, "Samples total (*.fam)");
					writer.setInteger(1, Integer.valueOf(value));
					writer.next();
				} else if (line.contains("* phenotypes")) {
					String value = line.split("=")[1].trim();
					writer.setString(0, "Number of defined phenotypes");
					writer.setInteger(1, Integer.valueOf(value));
					writer.next();
				} else if (line.contains("-number of phenotyped individuals")) {
					String value = line.split("=")[1].trim();
					writer.setString(0, "Phenotyped individuals total");
					writer.setInteger(1, Integer.valueOf(value));
					writer.next();
				} else if (line.contains("number of individuals used in analysis")) {
					String value = line.split("=")[1].trim();
					writer.setString(0, "Phenotyped individuals used");
					writer.setInteger(1, Integer.valueOf(value));
					writer.next();
				} else if (line.contains("--minMAC")) {
					String value = line.split("\\s+")[2].trim();
					writer.setString(0, "MAC limit");
					writer.setInteger(1, Integer.valueOf(value));
					writer.next();
				} else if (line.contains("--minINFO") && !line.contains("is skipped")) {
					String value = line.split("\\s+")[2].trim();
					writer.setString(0, "Imputation info score limit");
					writer.setDouble(1, Double.valueOf(value));
					writer.next();
				} else if (line.contains("Number of ignored SNPs due to low MAC or info score")) {
					String value = line.split(":")[1].trim();
					writer.setString(0, "Variants ignored (low MAC or low info score)");
					writer.setInteger(1, Integer.valueOf(value));
					writer.next();
				}
			}
			s.close();
		}

		if (countVariants > 0) {
			writer.setString(0, "Variants used (\\*.bgen or \\*.pvar)");
			writer.setInteger(1, Integer.valueOf(countVariants));
			writer.next();
		}

		if (files.size() > 1) {
			writer.setString(0, "Number of of parsed log files");
			writer.setInteger(1, files.size());
			writer.next();
		}

		if (warningMsgs.length() > 0) {
			writer.setString(0, "Warnings");
			writer.setString(1, warningMsgs.toString());
			writer.next();
		}

		writer.setString(0, "Regenie Call");
		writer.setString(1, optionsInEffect.toString());
		writer.next();

		writer.close();

		return 0;
	}

	public static void main(String... args) {
		int exitCode = new CommandLine(new RegenieLogParser()).execute(args);
		System.exit(exitCode);
	}

}
