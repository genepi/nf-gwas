
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

public class RegenieFilter implements Callable<Integer> {

	@Option(names = "--input", description = "Regenie file", required = true)
	private String input;

	@Option(names = "--limit", description = "Specifiy under logp value", required = true)
	private double limit;

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

		CsvTableWriter writer = new CsvTableWriter(new File(output).getAbsolutePath(), ' ', false);

		CsvTableReader reader = new CsvTableReader(input, ' ');

		writer.setColumns(reader.getColumns());

		while (reader.next()) {

			String value = reader.getString("LOG10P");
			if (value.equals("NA") || Double.valueOf(value) < limit) {
				continue;
			}
			writer.setRow(reader.getRow());
			writer.next();
		}

		reader.close();
		writer.close();
		return 0;
	}

	public static void main(String... args) {
		int exitCode = new CommandLine(new RegenieFilter()).execute(args);
		System.exit(exitCode);
	}

}
