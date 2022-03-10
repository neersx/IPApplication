using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.IntegrationServer.PtoAccess.FileApp.CpaXmlConversion;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.FileApp.Activities
{
    public interface IDetailsAvailable
    {
        Task ConvertToCpaXml(DataDownload dataDownload, Instruction instruction);
    }

    public class DetailsAvailable : IDetailsAvailable
    {
        readonly IBufferedStringWriter _bufferedStringWriter;
        readonly ICpaXmlConverter _cpaXmlConverter;
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver;

        public DetailsAvailable(ICpaXmlConverter cpaXmlConverter, 
            IDataDownloadLocationResolver dataDownloadLocationResolver, 
            IBufferedStringWriter bufferedStringWriter)
        {
            _cpaXmlConverter = cpaXmlConverter;
            _dataDownloadLocationResolver = dataDownloadLocationResolver;
            _bufferedStringWriter = bufferedStringWriter;
        }

        public async Task ConvertToCpaXml(DataDownload dataDownload, Instruction instruction)
        {
            if (dataDownload == null) throw new ArgumentNullException(nameof(dataDownload));

            var fileCase = dataDownload.GetExtendedDetails<FileCase>();
            
            var instructionDetails = JsonConvert.SerializeObject(new InstructionDetails(fileCase, instruction), Formatting.Indented);

            var cpaXml = await _cpaXmlConverter.Convert(dataDownload, fileCase, instruction);

            await _bufferedStringWriter.Write(
                                              _dataDownloadLocationResolver.Resolve(dataDownload, PtoAccessFileNames.CpaXml), cpaXml);

            await _bufferedStringWriter.Write(
                                              _dataDownloadLocationResolver.Resolve(dataDownload, PtoAccessFileNames.ApplicationDetails), instructionDetails);
        }
    }
    
    public class InstructionDetails
    {
        public FileCase FileCase { get; set; }

        public Instruction Instruction { get; set; }

        public InstructionDetails()
        {

        }

        public InstructionDetails(FileCase fileCase, Instruction instruction)
        {
            FileCase = fileCase;
            Instruction = instruction;
        }
    }
}