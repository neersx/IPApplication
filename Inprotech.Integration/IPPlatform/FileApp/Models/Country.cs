using System;
using Newtonsoft.Json;

namespace Inprotech.Integration.IPPlatform.FileApp.Models
{
    public class Country : IFileCountry
    {
        public string Code { get; set; }

        public string Agent { get; set; }

        public string Ref { get; set; }

        [JsonProperty("instructionUID", DefaultValueHandling = DefaultValueHandling.Ignore)]
        public Guid InstructionGuid { get; set; }

        [JsonProperty("class")]
        public string TmClass { get; set; }

        public Country()
        {
            
        }

        public Country(string code, string agent = null)
        {
            Code = code;
            Agent = agent;
        }

        public Country(string code, string className, string reference, string agent = null)
        {
            Code = code;
            TmClass = className;
            Ref = reference;
            Agent = agent;
        }
    }

    public static class CountrySelectionEx
    {
        public static Country ToCountry(this CountrySelection countrySelection)
        {
            return new Country
            {
                Code = countrySelection.Code,
                Agent = countrySelection.Agent,
                Ref = countrySelection.Irn,
                TmClass = string.IsNullOrWhiteSpace(countrySelection.Class) || countrySelection.Class.Split(',').Length > 1 
                        ? null
                        : countrySelection.Class
            };
        }
    }

    public interface IFileCountry
    {
        string Code { get; }

        string Agent { get;  }
    }
}