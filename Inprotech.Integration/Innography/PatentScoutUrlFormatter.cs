using System;
using System.Text.RegularExpressions;
using Inprotech.Integration.Innography.Ids;

namespace Inprotech.Integration.Innography
{
    public interface IPatentScoutUrlFormatter
    {
        Uri CreatePatentScoutReferenceLink(string ipId, bool singleSignOn);
    }
    
    public class PatentScoutUrlFormatter : IPatentScoutUrlFormatter
    {
        readonly InnographySetting _settings;

        public PatentScoutUrlFormatter(IPatentScoutSettingsResolver settingsResolver)
        {
            _settings = settingsResolver.Resolve();
        }

        public Uri CreatePatentScoutReferenceLink(string ipId, bool singleSignOn)
        {
            if (string.IsNullOrWhiteSpace(ipId))
                return null;

            if (!Regex.IsMatch(ipId, @"I-(\d{12})"))
                return null;

            var baseUri = _settings.ApiBase;

            var ipIdPath = $"patent/{ipId}";

            return singleSignOn 
                ? new Uri(baseUri, new Uri($"/oss?r={ipIdPath}", UriKind.Relative)) 
                : new Uri(baseUri, new Uri($"/{ipIdPath}", UriKind.Relative));
        }
    }
}