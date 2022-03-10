IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DependableJobs') AND EXISTS(SELECT TOP 1 * FROM DependableJobs)
BEGIN
	PRINT '**** R54246 One time migration for Dependable Jobs to use nuget package namespace'

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.ICpaXmlAssociatedCaseDetailsConverter, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.UsptoDataExtraction.CpaXml.ICpaXmlAssociatedCaseDetailsConverter, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.ICpaXmlAssociatedCaseDetailsConverter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.UsptoDataExtraction.CpaXml.ICpaXmlAssociatedCaseDetailsConverter, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.ICpaXmlAssociatedCaseDetailsConverter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.UsptoDataExtraction.CpaXml.ICpaXmlAssociatedCaseDetailsConverter, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.PrivatePair.DocumentList, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.UsptoDataExtraction.Activities.DocumentList, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.PrivatePair.DocumentList, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.UsptoDataExtraction.Activities.DocumentList, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.PrivatePair.DocumentList, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.UsptoDataExtraction.Activities.DocumentList, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.ICpaXmlCaseDetailsConverter, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.UsptoDataExtraction.CpaXml.ICpaXmlCaseDetailsConverter, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.ICpaXmlCaseDetailsConverter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.UsptoDataExtraction.CpaXml.ICpaXmlCaseDetailsConverter, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.ICpaXmlCaseDetailsConverter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.UsptoDataExtraction.CpaXml.ICpaXmlCaseDetailsConverter, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.CpaXmlCaseDetailsConverter, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.UsptoDataExtraction.CpaXml.CpaXmlCaseDetailsConverter, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.CpaXmlCaseDetailsConverter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.UsptoDataExtraction.CpaXml.CpaXmlCaseDetailsConverter, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.CpaXmlCaseDetailsConverter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.UsptoDataExtraction.CpaXml.CpaXmlCaseDetailsConverter, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.ICpaXmlSingleApplicationConverter, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.UsptoDataExtraction.CpaXml.ICpaXmlSingleApplicationConverter, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.ICpaXmlSingleApplicationConverter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.UsptoDataExtraction.CpaXml.ICpaXmlSingleApplicationConverter, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.ICpaXmlSingleApplicationConverter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.UsptoDataExtraction.CpaXml.ICpaXmlSingleApplicationConverter, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.CpaXmlSingleApplicationConverter, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.UsptoDataExtraction.CpaXml.CpaXmlSingleApplicationConverter, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.CpaXmlSingleApplicationConverter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.UsptoDataExtraction.CpaXml.CpaXmlSingleApplicationConverter, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.CpaXmlSingleApplicationConverter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.UsptoDataExtraction.CpaXml.CpaXmlSingleApplicationConverter, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.Activities.DocumentList, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.UsptoDataExtraction.PrivatePair.DocumentList, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.Activities.DocumentList, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.UsptoDataExtraction.PrivatePair.DocumentList, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.Activities.DocumentList, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.UsptoDataExtraction.PrivatePair.DocumentList, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.IBufferedStringReader, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.Storage.IBufferedStringReader, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.IBufferedStringReader, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.IBufferedStringReader, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.IBufferedStringReader, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.IBufferedStringReader, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.BufferedStringReader, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.Storage.BufferedStringReader, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.BufferedStringReader, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.BufferedStringReader, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.BufferedStringReader, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.BufferedStringReader, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.IBufferedStringWriter, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.Storage.IBufferedStringWriter, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.IBufferedStringWriter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.IBufferedStringWriter, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.IBufferedStringWriter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.IBufferedStringWriter, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.BufferedStringWriter, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.Storage.BufferedStringWriter, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.BufferedStringWriter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.BufferedStringWriter, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.BufferedStringWriter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.BufferedStringWriter, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.IChunkedStreamWriter, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.Storage.IChunkedStreamWriter, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.IChunkedStreamWriter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.IChunkedStreamWriter, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.IChunkedStreamWriter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.IChunkedStreamWriter, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.ChunkedStreamWriter, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.Storage.ChunkedStreamWriter, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.ChunkedStreamWriter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.ChunkedStreamWriter, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.ChunkedStreamWriter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.ChunkedStreamWriter, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.IContentHasher, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.Storage.IContentHasher, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.IContentHasher, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.IContentHasher, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.IContentHasher, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.IContentHasher, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.ContentHasher, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.Storage.ContentHasher, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.ContentHasher, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.ContentHasher, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.ContentHasher, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.ContentHasher, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.ICpaXmlReader, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.UsptoDataExtraction.CpaXml.ICpaXmlReader, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.ICpaXmlReader, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.UsptoDataExtraction.CpaXml.ICpaXmlReader, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.ICpaXmlReader, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.UsptoDataExtraction.CpaXml.ICpaXmlReader, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.CpaXmlReader, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.UsptoDataExtraction.CpaXml.CpaXmlReader, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.CpaXmlReader, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.UsptoDataExtraction.CpaXml.CpaXmlReader, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.CpaXmlReader, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.UsptoDataExtraction.CpaXml.CpaXmlReader, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.IPermanentStorageWriter, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.Storage.IPermanentStorageWriter, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.IPermanentStorageWriter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.IPermanentStorageWriter, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.IPermanentStorageWriter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.IPermanentStorageWriter, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.PermanentStorageWriter, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.Storage.PermanentStorageWriter, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.PermanentStorageWriter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.PermanentStorageWriter, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.PermanentStorageWriter, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.PermanentStorageWriter, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.PermanentStorageWriterExtentions, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.Storage.PermanentStorageWriterExtentions, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.PermanentStorageWriterExtentions, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.PermanentStorageWriterExtentions, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.PermanentStorageWriterExtentions, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Storage.PermanentStorageWriterExtentions, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.IZipStreamHelper, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.Compression.IZipStreamHelper, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.IZipStreamHelper, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Compression.IZipStreamHelper, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.IZipStreamHelper, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Compression.IZipStreamHelper, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction.ZipStreamHelper, Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.Compression.ZipStreamHelper, CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, '"Inprotech.Integration.UsptoDataExtraction.ZipStreamHelper, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Compression.ZipStreamHelper, CpaGlobal.Integration.UsptoDataExtraction"'),
		   ExceptionFilters = Replace(ExceptionFilters, '"Inprotech.Integration.UsptoDataExtraction.ZipStreamHelper, Inprotech.Integration.UsptoDataExtraction"', '"CpaGlobal.Integration.Compression.ZipStreamHelper, CpaGlobal.Integration.UsptoDataExtraction"')

	UPDATE DependableJobs
	SET    Type = Replace(Type, 'Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.UsptoDataExtraction'),
		   Arguments = Replace(Arguments, 'Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.UsptoDataExtraction'),
		   ExceptionFilters = Replace(ExceptionFilters, 'Inprotech.Integration.UsptoDataExtraction', 'CpaGlobal.Integration.UsptoDataExtraction') 
END
