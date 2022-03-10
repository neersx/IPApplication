using System;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.IPPlatform.FileApp.Models;

namespace Inprotech.Integration.IPPlatform.FileApp.Post
{
    public class FileTrademarkPostCreationTasks : IPostInstructionCreationTasks
    {
        readonly ILogger<FileTrademarkPostCreationTasks> _logger;
        readonly ITrademarkImageResolver _trademarkImageResolver;
        readonly IUploadTrademarkImage _uploadTrademarkImage;

        public FileTrademarkPostCreationTasks(ITrademarkImageResolver trademarkImageResolver, IUploadTrademarkImage uploadTrademarkImage, ILogger<FileTrademarkPostCreationTasks> logger)
        {
            _trademarkImageResolver = trademarkImageResolver;
            _uploadTrademarkImage = uploadTrademarkImage;
            _logger = logger;
        }

        public async Task Perform(FileSettings fileSettings, FileCase fileCase)
        {
            var image = await _trademarkImageResolver.Resolve(int.Parse(fileCase.Id));
            if (image == null) return;

            try
            {
                await _uploadTrademarkImage.Upload(image, fileSettings);
            }
            catch (Exception e)
            {
                _logger.Exception(e);
            }
        }
    }
}