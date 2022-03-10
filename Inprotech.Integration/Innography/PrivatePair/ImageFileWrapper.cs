using System;
using Inprotech.Infrastructure.Extensions;
using Newtonsoft.Json;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public class ImageFileWrapper
    {
        [JsonProperty("rowid")]
        public string RowId { get; set; }

        [JsonProperty("appid")]
        public string AppId { get; set; }

        [JsonProperty("mail_date")]
        public string MailDate { get; set; }

        [JsonProperty("doc_code")]
        public string DocCode { get; set; }

        [JsonProperty("doc_desc")]
        public string DocDesc { get; set; }

        [JsonProperty("page_count")]
        public int PageCount { get; set; }

        [JsonIgnore]
        public int Sequence { get; set; }

        [JsonIgnore]
        public DateTime MailDateParsed => DateTime.ParseExact(MailDate, "yyyy-MM-dd", null);

        [JsonProperty("filename")]
        public string FileName { get; set; }

        [JsonProperty("doc_category")]
        public string DocCategory { get; set; }

        [JsonProperty("object_id")]
        public string ObjectId { get; set; }
    }

    public static class FileWrapperExtensions
    {
        public static AvailableDocument ToAvailableDocument(this ImageFileWrapper file)
        {
            return new AvailableDocument
            {
                ObjectId = file.ObjectId,
                FileNameObjectId = file.FileName.IsNullOrEmpty()
                    ? null
                    : file.FileName.EndsWith(".pdf")
                        ? file.FileName.Remove(file.FileName.LastIndexOf(".pdf", StringComparison.InvariantCultureIgnoreCase), 4)
                        : file.FileName,
                DocumentCategory = file.DocCategory,
                MailRoomDate = file.MailDateParsed,
                DocumentDescription = file.DocDesc,
                FileWrapperDocumentCode = file.DocCode,
                PageCount = file.PageCount
            };
        }
    }
}