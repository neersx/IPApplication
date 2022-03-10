using System;
using System.Text;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Components.Names.Extensions
{
    public static class AssociatedNameExtension
    {
        public static string GetBestFitAssociatedName(this AssociatedName associatedName, Name name)
        {
            if(associatedName == null) throw new ArgumentNullException("associatedName");
            if(name == null) throw new ArgumentNullException("name");

            var bestFitMatch = new StringBuilder();
            bestFitMatch.Append(associatedName.CountryCode == null ? "1" : "0");
            bestFitMatch.Append(associatedName.PropertyTypeId == null ? "1" : "0");
            bestFitMatch.Append(associatedName.RelatedNameId == name.MainContactId ? "0" : "1");
            bestFitMatch.Append(new string('0', 6 - Convert.ToString(associatedName.Sequence).Length));
            bestFitMatch.Append(Convert.ToString(associatedName.Sequence));
            bestFitMatch.Append(Convert.ToString(associatedName.RelatedNameId));
            return bestFitMatch.ToString();
        }
    }
}