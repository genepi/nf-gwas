//usr/bin/env jbang "$0" "$@" ; exit $?
//REPOS jcenter,jfrog-genepi-maven=https://genepi.jfrog.io/artifactory/maven/
//DEPS info.picocli:picocli:4.6.1
//DEPS genepi:genepi-io:1.1.1

import java.io.File;
import java.util.concurrent.Callable;

import org.apache.commons.io.FilenameUtils;

import genepi.io.table.reader.CsvTableReader;
import genepi.io.table.writer.CsvTableWriter;
import picocli.CommandLine;
import picocli.CommandLine.Option;

public class RegenieValidateInput implements Callable<Integer> {

	@Option(names = "--input", description = "Regenie input file", required = true)
	private String input;

	@Option(names = "--output", description = "Regenie input file validated", required = true)
	private String output;

	@Option(names = "--type", description = "File type", required = true)

	private String type;

	public void setInput(String input) {
		this.input = input;
	}

	public void setOutput(String output) {
		this.output = output;
	}

	private static String REGENIE_MISSING = "NA";

	public Integer call() throws Exception {

		assert (input != null);
		assert (output != null);

		CsvTableWriter writer = new CsvTableWriter(new File(output).getAbsolutePath(), '\t', false);

		String logFile = FilenameUtils.getFullPath(output) + FilenameUtils.getBaseName(output) + ".log";
		CsvTableWriter logWriter = new CsvTableWriter(new File(logFile).getAbsolutePath(), '\t', false);

		CsvTableReader reader = new CsvTableReader(input, '\t');

		if (reader.getColumns().length == 1) {

			reader.close();
			reader = new CsvTableReader(input, ' ');

			if (reader.getColumns().length == 1) {
				System.err.println("ERROR: Input file '" + input + "' must be TAB or SPACE seperated.");
				return -1;
			}
		}

		if (!reader.getColumns()[0].equals("FID") || !reader.getColumns()[1].equals("IID")) {
			System.err.println("ERROR: header of file '" + input + "' must start with 'FID IID'.");
			return -1;
		}

		writer.setColumns(reader.getColumns());

		String[] columnsWrite = { "Name", "Value" };
		logWriter.setColumns(columnsWrite);

		int line = 1;
		int emptyValues = 0;
		while (reader.next()) {
			line++;
			if (reader.getRow().length != reader.getColumns().length) {
				System.err.println(
						"ERROR: Input file '" + input + "' parse error in line " + line + ". Detected columns: "
								+ reader.getRow().length + ". Expected columns: " + reader.getColumns().length + ".");
				return -1;
			}

			String[] row = reader.getRow();

			if (type.equals("phenotype")) {

				for (int i = 0; i < row.length; i++) {

					// replace empty values WITH NA
					if (row[i].isEmpty()) {
						emptyValues++;
						row[i] = row[i].replace("", REGENIE_MISSING);
					}

				}
			} else if (type.equals("covariate")) {

				for (int i = 0; i < row.length; i++) {

					// replace empty values WITH NA
					if (row[i].isEmpty()) {
						throw new Exception("ERROR: Line " + line + " includes an empty value in column " + i + ".");
					}

				}

			}

			writer.setRow(row);
			writer.next();
		}

		reader.close();
		writer.close();

		logWriter.setString(0, "Samples count");
		logWriter.setInteger(1, line - 1);
		logWriter.next();

		if (type.equals("phenotype")) {
			logWriter.setString(0, "Empty values replaced with NA");
			logWriter.setInteger(1, emptyValues);
		}

		logWriter.next();

		logWriter.close();

		return 0;
	}

	public static void main(String... args) {
		int exitCode = new CommandLine(new RegenieValidateInput()).execute(args);
		System.exit(exitCode);
	}

}
