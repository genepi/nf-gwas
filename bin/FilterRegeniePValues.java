//usr/bin/env jbang "$0" "$@" ; exit $?
//REPOS jcenter,bintry-genepi-maven=https://dl.bintray.com/genepi/maven
//DEPS info.picocli:picocli:4.6.1
//DEPS genepi:genepi-io:1.1.1

import java.io.File;
import java.util.concurrent.Callable;

import genepi.io.table.reader.CsvTableReader;
import genepi.io.table.writer.CsvTableWriter;
import picocli.CommandLine;
import picocli.CommandLine.Option;

public class FilterRegeniePValues implements Callable<Integer> {

	@Option(names = "--input", description = "Regenie file", required = true)
	private String input;

	@Option(names = "--limit", description = "Specifiy under logp value", required = true)
	private double limit;

	@Option(names = "--output", description = "Fitlered Regenie file ", required = true)
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

			String[] columnsWrite = { "CHROM", "GENPOS", "ID", "ALLELE0", "ALLELE1", "A1FREQ", "INFO", "N",
					"TEST", "BETA", "SE", "CHISQ", "LOG10P", "EXTRA" };
			writer.setColumns(columnsWrite);
	

		CsvTableReader reader = new CsvTableReader(input, ' ');
		
		while (reader.next()) {

			if (reader.getDouble("LOG10P") < limit) {
				continue;
			}

			writer.setInteger(0, reader.getInteger("CHROM"));
			writer.setInteger(1, reader.getInteger("GENPOS"));
			writer.setString(2, reader.getString("ID"));
			writer.setString(3, reader.getString("ALLELE0"));
			writer.setString(4, reader.getString("ALLELE1"));
			writer.setDouble(5, reader.getDouble("A1FREQ"));
			writer.setDouble(6, reader.getDouble("INFO"));
			writer.setDouble(7, reader.getDouble("N"));
			writer.setString(8, reader.getString("TEST"));
			writer.setDouble(9, reader.getDouble("BETA"));
			writer.setDouble(10, reader.getDouble("SE"));
			writer.setDouble(11, reader.getDouble("CHISQ"));
			writer.setDouble(12, reader.getDouble("LOG10P"));
			writer.setString(13, reader.getString("EXTRA"));
			writer.next();
		}

		writer.close();
		return 0;
	}

	public static void main(String... args) {
		int exitCode = new CommandLine(new FilterRegeniePValues()).execute(args);
		System.exit(exitCode);
	}

}
