using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using Newtonsoft.Json;

namespace Inprotech.Integration.IPPlatform.FileApp.Models
{
    public class FileCase
    {
        public FileCase()
        {
            BibliographicalInformation = new Biblio();
            Countries = new List<Country>();
            Links = new List<Link>();
        }

        public string Id { get; set; }

        public string IpType { get; set; }

        [JsonProperty("clientRef")]
        public string CaseReference { get; set; }

        [JsonProperty("caseGUID")]
        public string CaseGuid { get; set; }

        public string DeadlineDate { get; set; }
        
        public string ApplicantName { get; set; }

        public string Permalink { get; set; }

        [JsonProperty("bibliographicalData")]
        public Biblio BibliographicalInformation { get; set; }

        public ICollection<Country> Countries { get; set; }

        public string Status { get; set; }

        public ICollection<Link> Links { get; set; }
        
        public void RemoveCountries(IEnumerable<string> countryCodes)
        {
            Countries = Countries.Where(_ => !countryCodes.Contains(_.Code)).ToList();
        }

        public void AddCountries(IEnumerable<Country> countries)
        {
            Countries.AddRange(countries);
        }
    }
}