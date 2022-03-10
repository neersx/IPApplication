using System;
using Microsoft.WindowsAzure.Storage.Blob;

namespace Inprotech.Integration.IPPlatform.FileApp.Post
{
    public interface IFileImageStorageHandler
    {
        ICloudBlob Create(Uri uri);
    }

    public class FileImageStorageHandler : IFileImageStorageHandler
    {
        public ICloudBlob Create(Uri uri)
        {
            return new CloudBlockBlob(uri);
        }
    }

}
