//usr/bin/env jbang "$0" "$@" ; exit $?
//REPOS jcenter,jfrog-genepi-maven=https://genepi.jfrog.io/artifactory/maven/
//DEPS info.picocli:picocli:4.6.1
//DEPS genepi:genepi-io:1.1.1

import java.io.File;
import java.util.Arrays;
import java.util.concurrent.Callable;
import org.apache.commons.io.FilenameUtils;
import genepi.io.table.reader.CsvTableReader;
import genepi.io.table.writer.CsvTableWriter;
import picocli.CommandLine;
import picocli.CommandLine.Option;

public class RegenieValidateInput implements Callable<Integer> {

	@Option(names = "--input", description = "Input file", required = true)
	private String input;

	@Option(names = "--output", description = "Validated output file", required = true)
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

	enum TYPE {
		phenotype, covariate
	}

	public Integer call() throws Exception {

		assert (input != null);
		assert (output != null);

		CsvTableWriter writer = new CsvTableWriter(new File(output).getAbsolutePath(), '\t', false);

		String logFile = FilenameUtils.getFullPath(output) + FilenameUtils.getBaseName(output) + ".log";

		CsvTableWriter logWriter = new CsvTableWriter(new File(logFile).getAbsolutePath(), '\t', false);

		CsvTableReader reader = new CsvTableReader(input, '\t');

		String[] columnsWrite = { "Name", "Value" };

		logWriter.setColumns(columnsWrite);

		if (reader.getColumns().length == 1) {

			reader.close();

			reader = new CsvTableReader(input, ' ');

			if (reader.getColumns().length == 1) {
				System.err.println("ERROR: Input file '" + input + "' must be TAB or SPACE seperated.");
				return -1;
			}

		}

		String[] columns = reader.getColumns();

		columns[0] = columns[0].toUpperCase();
		columns[1] = columns[1].toUpperCase();

		writer.setColumns(columns);

		Integer[] countEmptyValues = new Integer[columns.length];
		Arrays.fill(countEmptyValues, 0);

		Integer[] countNAValues = new Integer[columns.length];
		Arrays.fill(countNAValues, 0);

		if (columns.length < 3) {
			System.err.println("ERROR: File only includes 2 columns.");
			return -1;
		}

		if (!columns[0].equals("FID") || !columns[1].equals("IID")) {
			System.err.println("ERROR: header of file '" + input + "' must start with 'FID IID'.");
			return -1;
		}

		int line = 0;
		while (reader.next()) {

			line++;

			if (reader.getRow().length != reader.getColumns().length) {
				System.err.println(
						"ERROR: Input file '" + input + "' parse error in line " + line + ". Detected columns: "
								+ reader.getRow().length + ". Expected columns: " + reader.getColumns().length + ".");
				return -1;
			}

			String[] row = reader.getRow();

			RegenieValidateInput.TYPE typeEnum = TYPE.valueOf(type);

			if (typeEnum == TYPE.phenotype) {

				for (int i = 2; i < columns.length; i++) {

					if (row[i].isEmpty() || row[i].equals(".")) {

						countEmptyValues[i] = countEmptyValues[i] + 1;

						row[i] = row[i].replace("", REGENIE_MISSING);

					} else if (row[i].equals("NA")) {

						countNAValues[i] = countNAValues[i] + 1;

					}

				}
			}

			if (typeEnum == TYPE.covariate) {

				for (int i = 0; i < row.length; i++) {

					// check for empty values
					if (row[i].isEmpty()) {
						throw new Exception(
								"ERROR: Sample " + row[0] + " includes an empty value in column " + i + ".");
					}

				}

			}

			writer.setRow(row);
			writer.next();
		}

		logWriter.setString(0, "Samples");
		logWriter.setInteger(1, line);
		logWriter.next();

		for (int i = 0; i < countEmptyValues.length; i++) {

			if (countEmptyValues[i] != 0) {

				logWriter.setString(0,
						"[Phenotype  " + reader.getColumns()[i] + "] NA-replaced empty values");
				logWriter.setInteger(1, countEmptyValues[i]);
				logWriter.next();

			}
		}

		for (int i = 0; i < countNAValues.length; i++) {

			if (countNAValues[i] != 0) {

				logWriter.setString(0, "[Phenotype  " + reader.getColumns()[i] + "] NA values");
				logWriter.setInteger(1, countNAValues[i]);
				logWriter.next();

			}
		}

		logWriter.close();
		reader.close();
		writer.close();

		return 0;
	}

	public static void main(String... args) {
		int exitCode = new CommandLine(new RegenieValidateInput()).execute(args);
		System.exit(exitCode);
	}

}
