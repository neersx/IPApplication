using System;
using System.IO;

namespace Inprotech.Contracts.Storage
{
    public class FileContent
    {
        public readonly Stream Content;
        public readonly Guid FileId;

        public FileContent(Stream content, Guid fileId)
        {
            if(content == null) throw new ArgumentNullException("content");
            if(fileId == Guid.Empty) throw new ArgumentNullException("fileId");
            Content = content;
            FileId = fileId;
        }
    }
}