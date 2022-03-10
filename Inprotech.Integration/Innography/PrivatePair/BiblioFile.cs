using System.Collections.Generic;
using Newtonsoft.Json;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public class BiblioFile
    {
        [JsonProperty("Bibliographic Summary")]
        public BiblioSummary Summary { get; set; }

        [JsonProperty("Image File Wrapper")]
        public List<ImageFileWrapper> ImageFileWrappers { get; set; }

        [JsonProperty("Continuity")]
        public List<Continuity> Continuity { get; set; }

        [JsonProperty("Foreign Priority")]
        public List<ForeignPriority> ForeignPriority { get; set; }

        [JsonProperty("Transaction History")]
        public List<TransactionHistory> TransactionHistory { get; set; }

        public BiblioFile()
        {
            Summary = new BiblioSummary();
            ImageFileWrappers = new List<ImageFileWrapper>();
            Continuity = new List<Continuity>();
            ForeignPriority = new List<ForeignPriority>();
            TransactionHistory = new List<TransactionHistory>();
        }
    }
}