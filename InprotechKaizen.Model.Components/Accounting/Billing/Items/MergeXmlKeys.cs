using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Infrastructure.Extensions;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items
{
    public class OpenItemXmlKey
    {
        public int ItemEntityNo { get; set; }

        public int ItemTransNo { get; set; }
    }

    public class MergeXmlKeys
    {
        public MergeXmlKeys()
        {
            
        }

        public MergeXmlKeys(XElement mergeXmlKeys)
        {
            if (mergeXmlKeys != null)
            {
                OpenItemXmls.AddRange(from m in mergeXmlKeys.Descendants("Key")
                                      select new OpenItemXmlKey
                                      {
                                          ItemEntityNo = (int)m.Element("ItemEntityNo"),
                                          ItemTransNo = (int)m.Element("ItemTransNo")
                                      });
            }
        }

        public MergeXmlKeys(string mergeXmlKeys)
        {
            if (!string.IsNullOrWhiteSpace(mergeXmlKeys))
            {
                OpenItemXmls.AddRange(from m in XElement.Parse(mergeXmlKeys).Descendants("Key")
                                      select new OpenItemXmlKey
                                      {
                                          ItemEntityNo = (int) m.Element("ItemEntityNo"),
                                          ItemTransNo = (int) m.Element("ItemTransNo")
                                      });
            }
        }

        public ICollection<OpenItemXmlKey> OpenItemXmls { get; } = new List<OpenItemXmlKey>();

        public override string ToString()
        {
            if (!OpenItemXmls.Any())
                return string.Empty;

            return new XElement("Keys",
                                OpenItemXmls.Select(openItem => new XElement("Key",
                                                                             new XElement("ItemEntityNo", openItem.ItemEntityNo),
                                                                             new XElement("ItemTransNo", openItem.ItemTransNo)
                                                                            ))
                               ).ToString();
        }
    }
}