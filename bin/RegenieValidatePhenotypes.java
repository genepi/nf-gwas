
//usr/bin/env jbang "$0" "$@" ; exit $?
//REPOS jcenter,jfrog-genepi-maven=https://genepi.jfrog.io/artifactory/maven/
//DEPS info.picocli:picocli:4.6.1
//DEPS genepi:genepi-io:1.1.1

import java.io.File;
import java.util.concurrent.Callable;
import genepi.io.table.reader.CsvTableReader;
import genepi.io.table.writer.CsvTableWriter;
import picocli.CommandLine;
import picocli.CommandLine.Option;

public class RegenieValidatePhenotypes implements Callable<Integer> {

	@Option(names = "--input", description = "Regenie file", required = true)
	private String input;

	@Option(names = "--output", description = "Filtered Regenie file ", required = true)
	private String output;

	public void setInput(String input) {
		this.input = input;
	}

	public void setOutput(String output) {
		this.output = output;
	}

	public Integer call() throws Exception {

		assert (input != null);
		assert (output != null);

		CsvTableWriter writer = new CsvTableWriter(new File(output).getAbsolutePath(), '\t', false);

		CsvTableReader reader = new CsvTableReader(input, '\t');

		if (reader.getColumns().length == 1) {
			reader.close();
			reader = new CsvTableReader(input, ' ');

			if (reader.getColumns().length == 1) {
				System.err.println("ERROR: Input file must be TAB or SPACE seperated.");
				return -1;
			}
		}

		if (!reader.getColumns()[0].equals("FID") || !reader.getColumns()[1].equals("IID")) {
			System.err.println("ERROR: header of phenotype file must start with: FID IID.");
			return -1;
		}

		writer.setColumns(reader.getColumns());

		int line = 1;
		while (reader.next()) {
			line++;
			if (reader.getRow().length != reader.getColumns().length) {
				System.err.println("ERROR: Input file parse error in line " + line + ". Detected columns: "
						+ reader.getRow().length + ". Expected columns: " + reader.getColumns().length + ".");
				return -1;
			}
			writer.setRow(reader.getRow());
			writer.next();
		}

		reader.close();
		writer.close();
		return 0;
	}

	public static void main(String... args) {
		int exitCode = new CommandLine(new RegenieValidatePhenotypes()).execute(args);
		System.exit(exitCode);
	}

}
