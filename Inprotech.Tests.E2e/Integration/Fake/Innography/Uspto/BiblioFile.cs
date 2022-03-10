using System;
using System.Collections.Generic;
using Newtonsoft.Json;

namespace Inprotech.Tests.E2e.Integration.Fake.Innography.Uspto
{
    class Service
    {
        public string PublicKey { get; set; }

        public byte[] IV { get; set; }

        public byte[] Decrypter { get; set; }

        public string IvEncryptedBase64String { get; set; }

        public string DecrypterEncryptedBase64String { get; set; }
    }

    class LinkInfo
    {
        [JsonProperty("type")]
        public string Type { get; set; }

        [JsonProperty("status")]
        public string Status { get; set; }

        [JsonProperty("message")]
        public string Message { get; set; }

        [JsonProperty("link")]
        public string Link { get; set; }

        [JsonProperty("decrypter")]
        public string Decrypter { get; set; }

        [JsonProperty("iv")]
        public string Iv { get; set; }
    }

    class BiblioFile
    {
        [JsonProperty("Bibliographic Summary")]
        public BiblioSummary Summary { get; set; }

        [JsonProperty("Image File Wrapper")]
        public List<ImageFileWrapper> ImageFileWrappers { get; set; }

        [JsonProperty("Foreign Priority")]
        public List<ForeignPriority> ForeignPriority { get; set; }

        public BiblioFile()
        {
            Summary = new BiblioSummary();
            ImageFileWrappers = new List<ImageFileWrapper>();
            ForeignPriority = new List<ForeignPriority>();
        }
    }

    class BiblioSummary
    {
        [JsonProperty("appid")]
        public string AppId { get; set; }

        [JsonProperty("app_number")]
        public string AppNumber { get; set; }

        [JsonProperty("customer_number")]
        public string CustomerNumber { get; set; }

        [JsonProperty("title")]
        public string Title { get; set; }
    }

    class ImageFileWrapper
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
        public DateTime MailDateTime => DateTime.Parse(MailDate);

        [JsonProperty("filename")]
        public string FileName { get; set; }

        [JsonProperty("doc_category")]
        public string DocCategory { get; set; }

        [JsonProperty("ts")]
        public DateTime TimeStamp { get; set; }

        [JsonProperty("object_id")]
        public string ObjectId { get; } = RandomString.Next(20);

        public ImageFileWrapper CalculatingFileName()
        {
            FileName = $"{AppId}-{MailDate}-{Sequence.ToString().PadLeft(5, '0')}-{DocCode.Replace('/','-')}.pdf";
            return this;
        }
    }

    public class ForeignPriority
    {
        [JsonProperty("country")]
        public string Country { get; set; }

        [JsonProperty("priority")]
        public string ForeignPriorityNumber { get; set; }

        [JsonProperty("priority_date")]
        public string ForeignPriorityDate { get; set; }
    }
}