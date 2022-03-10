using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using InprotechKaizen.Model.SchemaMappings;

namespace Inprotech.Integration.SchemaMapping
{
    internal interface IDtdReader
    {
        DtdParseResult Convert(SchemaFile file, List<SchemaFile> packageSchemaFiles);
    }

    class DtdParseResult
    {
        public DtdParseResult()
        {
            MissingDependecies = new List<string>();
            LoadedDependecies = new List<string>();
        }
        public string Xsd { get; set; }
        public List<string> MissingDependecies { get; set; }
        public List<string> LoadedDependecies { get; set; }
    }

    internal class DtdReader : IDtdReader
    {
        const RegexOptions Opt = RegexOptions.Singleline | RegexOptions.IgnoreCase;
        const string Str = "(?:\"([^\"]*)\"|\'([^\']*)\')";
        readonly int _alias = 0;

        readonly List<string> _attrGroupPatterns = new List<string>();
        readonly Dictionary<string, string[]> _attributes = new Dictionary<string, string[]>(); // Attribute lists

        readonly List<string> _elements = new List<string>(); // Elements in source order
        readonly Dictionary<string, int> _mixed = new Dictionary<string, int>();
        readonly Dictionary<string, string[]> _modelContent = new Dictionary<string, string[]>(); // Content models
        readonly Dictionary<string, Elements[]> _modelGroup = new Dictionary<string, Elements[]>();
        readonly List<string> _modelGroupPatterns = new List<string>();

        readonly Dictionary<string, string> _paramEntries = new Dictionary<string, string>(); // Parameter entities
        readonly int _pcdataFlag = 1;
        readonly string _pcdataSimpletype = "string";
        readonly string _prefix = "t";

        readonly StringBuilder _sb = new StringBuilder();

        readonly Hashtable _simpleTypes = new Hashtable();
        readonly Dictionary<string, string> _substitutionGroup = new Dictionary<string, string>();
        readonly List<string> _substitutionGroupPatterns = new List<string>();
        readonly string alias_ident = "_alias_";
        string _buf;
        MatchCollection _matches;
        readonly List<string> _loaded = new List<string>();
        readonly List<string> _required = new List<string>();
        List<SchemaFile> _schemaFiles;

        readonly Hashtable _aliasDic = new Hashtable
                                       {
                                           {"URI", "uriReference"},
                                           {"LANG", "language"},
                                           {"NUMBER", "nonNegativeInteger"},
                                           {"Date", "date"},
                                           {"Boolean", "boolean"}
                                       };

        readonly Dictionary<DtdOccurance, string> _occuranceValues = new Dictionary<DtdOccurance, string>
                                                                     {
                                                                         {DtdOccurance.Default, Values.Empty},
                                                                         {DtdOccurance.ZeroOrMore, Values.ZeroOrMore},
                                                                         {DtdOccurance.OneOrMore, Values.OneOrMore},
                                                                         {DtdOccurance.Optional, Values.Optional}
                                                                     };

        readonly Dictionary<string, DtdOccurance> _occurranceIndicator = new Dictionary<string, DtdOccurance>
                                                                         {
                                                                             {"*", DtdOccurance.ZeroOrMore},
                                                                             {"+", DtdOccurance.OneOrMore},
                                                                             {"?", DtdOccurance.Optional}
                                                                         };
        
        public DtdParseResult Convert(SchemaFile file, List<SchemaFile> packageSchemaFiles)
        {
            var resp = new DtdParseResult();
            _schemaFiles = packageSchemaFiles;

            var dtdContent = ReadFileContent(file.Name, false);

            _buf = PrepareRawFileContent(dtdContent);
            resp.LoadedDependecies = _loaded;
            resp.MissingDependecies = _required;

            if (resp.MissingDependecies.Any())
                return resp;

            AliasTreatment();

            StoreParameterEntities();

            //# remove all general entities
            _buf = Regex.Replace(_buf, @"<!ENTITY\s+.*?>", string.Empty, Opt);

            ExpandParameterEntities();

            HandleIncludes();

            //            # store attribute lists
            _buf = Regex.Replace(_buf, @"<!ATTLIST\s+(\S+)\s+(.*?)>",
                                 _ => StoreAtt(_.Groups[1].Value, _.Groups[2].Value), Opt);

            //# store content models, all the elements
            _buf = Regex.Replace(_buf, @"<!ELEMENT\s+(\S+)\s+(.+?)>",
                                 _ => StoreElement(_.Groups[1].Value, _.Groups[2].Value), Opt);

            AppendSchemaHeader();

            //# write simple type declarations
            _buf = Regex.Replace(_buf, @"<!_DATATYPE\s+(\S+)\s+(\S+)\s+(.+?)>",
                                 _ => AppendSimpleType(_.Groups[1].Value, _.Groups[2].Value, _.Groups[3].Value), Opt);

            //# write attribute groups
            _buf = Regex.Replace(_buf, @"<!_ATTRGROUP\s+(\S+)\s+(.+?)>",
                                 _ => AppendAttrGroup(_.Groups[1].Value, _.Groups[2].Value), Opt);

            //# write model groups
            _buf = Regex.Replace(_buf, @"<!_MODELGROUP\s+(\S+)\s+(.+?)>",
                                 _ => AppendAndStoreModelGroup(_.Groups[1].Value, _.Groups[2].Value), Opt);
            //$buf =~ s/<!_MODELGROUP\s+(\S+)\s+(.+?)>/write_modelGroup($1, $2)/gsie;

            //# write subsitution groups
            _buf = Regex.Replace(_buf, @"<!_SUBSTGROUP\s+(\S+)\s+(.+?)>",
                                 _ => AppendAndStoreSubstitutionGroup(_.Groups[1].Value, _.Groups[2].Value), Opt);

            BuildXmlSchemaContent();
            resp.Xsd = _sb.ToString();
            return resp;
        }

        string PrepareRawFileContent(string dtdContent)
        {
            var extent = new Dictionary<string, string>();
            var opt = RegexOptions.Singleline | RegexOptions.IgnoreCase;

            // remove comments
            dtdContent = Regex.Replace(dtdContent, "<!--.*?-->", string.Empty, RegexOptions.Singleline);

            // remove processing instructions
            dtdContent = Regex.Replace(dtdContent, @"<\?.*?>", string.Empty, RegexOptions.Singleline);

            MatchCollection matches;
            // store external parameter entities
            string pattern = $@"<!ENTITY\s+%\s+(\S+)\s+PUBLIC\s+{Str}\s+{Str}.*?>";
            while ((matches = Regex.Matches(dtdContent, pattern, opt)).Count > 0)
            {
                dtdContent = Regex.Replace(dtdContent, pattern, string.Empty, opt);
                foreach (Match match in matches)
                {
                    extent[match.Groups[1].Value] = match.Groups[4].Value + match.Groups[5].Value;
                }
            }

            pattern = $@"<!ENTITY\s+%\s+(\S+)\s+SYSTEM\s+{Str}.*?>";
            while ((matches = Regex.Matches(dtdContent, pattern, opt)).Count > 0)
            {
                dtdContent = Regex.Replace(dtdContent, pattern, string.Empty, opt);
                foreach (Match match in matches)
                {
                    extent[match.Groups[1].Value] = match.Groups[2].Value + match.Groups[3].Value;
                }
            }

            //# read external entity files
            foreach (var key in extent.Keys)
            {
                var external = ReadFileContent(extent[key]);
                if (!string.IsNullOrEmpty(external))
                    dtdContent = Regex.Replace(dtdContent, "%" + key, PrepareRawFileContent(external), opt);
            }

            return dtdContent;
        }

        string ReadFileContent(string filename, bool isDependentFile = true)
        {
            var schemaFile = _schemaFiles.SingleOrDefault(_ => _.Name == filename);
            if (schemaFile == null)
            {
                _required.Add(filename);
                return null;
            }
            if (isDependentFile)
                _loaded.Add(filename);

            return schemaFile.Content;
        }

        void AliasTreatment()
        {
            if (_alias == 1)
            {
                foreach (var key in _aliasDic.Keys)
                {
                    var aliasKey = $"{alias_ident}{key}{alias_ident}";
                    _buf = Regex.Replace(_buf, $"%{key};", aliasKey, RegexOptions.Singleline);
                }
            }
        }

        //store all parameter entities
        void StoreParameterEntities()
        {
            _matches = null;
            string pattern = $@"<!ENTITY\s+%\s+(\S+)\s+{Str}\s*>";

            while ((_matches = Regex.Matches(_buf, pattern, Opt)).Count > 0)
            {
                _buf = Regex.Replace(_buf, pattern, string.Empty, Opt);
                foreach (Match match in _matches)
                {
                    var n = match.Groups[1].Value;
                    var repltext = match.Groups[2].Value + match.Groups[3].Value;

                    if (_paramEntries.ContainsKey(n)) continue;

                    foreach (string pat in _simpleTypes.Keys)
                    {
                        if (Regex.IsMatch(n, $"^{pat}$"))
                        {
                            _buf += $" <!_DATATYPE {n} {_simpleTypes[pat]} {repltext}> ";
                            _paramEntries[n] = "#DATATYPEREF " + n;
                            n = null;
                            break;
                        }
                    }

                    foreach (var pat in _attrGroupPatterns)
                    {
                        if (Regex.IsMatch(n, "^" + pat + "$"))
                        {
                            _buf += $" <!_ATTRGROUP {n} {repltext}> ";
                            _paramEntries[n] = "#ATTRGROUPREF " + n;
                            n = null;
                            break;
                        }
                    }

                    foreach (var pat in _modelGroupPatterns)
                    {
                        if (Regex.IsMatch(n, "^" + pat + "$"))
                        {
                            _buf += $" <!_MODELGROUP {n} {repltext}> ";
                            _paramEntries[n] = "#MODELGROUPREF " + n;
                            n = null;
                            break;
                        }
                    }

                    foreach (var pat in _substitutionGroupPatterns)
                    {
                        if (Regex.IsMatch(n, "^" + pat + "$"))
                        {
                            _buf += $" <!_SUBSTGROUP {n} {repltext}> ";
                            _paramEntries[n] = "#SUBSTGROUPREF " + n;
                            n = null;
                            break;
                        }
                    }
                    if (!string.IsNullOrEmpty(n))
                        _paramEntries[n] = repltext;
                }
            }
        }

        void ExpandParameterEntities()
        {
            //# loop until parameter entities fully expanded
            int i;
            do
            {
                //# count # of substitutions
                i = 0;
                //# expand parameter entities
                _buf = Regex.Replace(_buf, @"%([a-zA-Z0-9_\.-]+);?", _ =>
                                                                     {
                                                                         i++;
                                                                         return _paramEntries[_.Groups[1].Value];
                                                                     }, RegexOptions.Singleline);
            }
            while (i != 0);
        }

        void HandleIncludes()
        {
            // # treat conditional sections
            _matches = null;
            var pattern = @"<!\[\s*?INCLUDE\s*?\[(.*)\]\]>";
            while ((_matches = Regex.Matches(_buf, pattern, Opt)).Count > 0)
            {
                _buf = Regex.Replace(_buf, pattern, @"\1", Opt);
            }
            pattern = @"<!\[\s*?IGNORE\s*?\[.*\]\]>";
            while ((_matches = Regex.Matches(_buf, pattern, Opt)).Count > 0)
            {
                _buf = Regex.Replace(_buf, pattern, string.Empty, Opt);
            }
        }

        void AppendSchemaHeader()
        {
            _sb.Append("<?xml version='1.0' encoding='utf-8'?>\n");
            _sb.Append($@"<schema xmlns = 'http://www.w3.org/2001/XMLSchema' targetNamespace = '{Constants.TempNameSpace}' xmlns:{_prefix} = '{Constants.TempNameSpace}' >");
        }

        //# Store attribute list, returns empty string
        string StoreAtt(string elementName, string atts)
        {
            var words = ParseWords(atts);
            _attributes[elementName] = words;
            return string.Empty;
        }

        //# Store content model, returns empty string
        string StoreElement(string name, string model)
        {
            model = Regex.Replace(model, @"\s+", " ", Opt);
            _elements.Add(name);

            var words = new List<string>();
            MatchCollection matches;
            var pattern = @"^\s*(\(|\)|,|\+|\?|\||[\w_\.-]+|\#\w+|\*)";
            while ((matches = Regex.Matches(model, pattern)).Count > 0)
            {
                model = Regex.Replace(model, pattern, string.Empty);
                foreach (Match match in matches)
                {
                    words.Add(match.Groups[1].Value);
                }
            }
            _modelContent[name] = words.ToArray();
            return string.Empty;
        }

        //returns empty string
        string AppendSimpleType(string n, string b, string stuff)
        {
            var words = ParseWords(stuff);

            _sb.Append($"\n  <simpleType name='{n}'>\n");
            _sb.Append($"   <restriction base='{b}'>\n");
            //#    print STDERR "\n==stuff:\n$stuff \n\n===\n", join('|', @words);

            var i = 0;
            var enume = new List<string>();

            if (words[i] == "(")
            {
                i++;
                while (words[i] != ")")
                {
                    if (words[i] != "|")
                    {
                        enume.Add(words[i]);
                    }
                    i++;
                }
                AppendEnum(enume.ToArray());
            }

            _sb.Append("   </restriction>\n");
            _sb.Append("  </simpleType>\n");
            return string.Empty;
        }

        //returns empty string
        string AppendAttrGroup(string n, string stuff)
        {
            var words = ParseWords(stuff);

            _sb.Append($"\n  <attributeGroup name='{n}'>\n");
            //# print STDERR "\n==stuff:\n$stuff \n\n===\n", join('|', @words);
            AppendAttrDecls(words);
            _sb.Append(" </attributeGroup>\n");
            return string.Empty;
        }

        //returns empty string
        string AppendAndStoreModelGroup(string n, string stuff)
        {
            var words = ParseWords(stuff).ToList();

            _sb.Append($"\n  <group name='{n}'>\n");
            _sb.Append($"<!-- {stuff} -->\n");

            words.Insert(0, "(");
            words.Add(")");
            var list = MakeChildList(n, words.ToArray());
            PrintChildList(3, list);

            _modelGroup[n] = list;

            _sb.Append("  </group>\n");
            return string.Empty;
        }

        //returns empty string
        string AppendAndStoreSubstitutionGroup(string n, string stuff)
        {
            var words = ParseWords(stuff).ToList();

            _sb.Append($"\n  <element name='{n}' abstract='true'>\n");

            words.Insert(0, "(");
            words.Add(")");
            var list = MakeChildList(n, words.ToArray());
            for (var i = 0; i < list.Length; i++)
            {
                _substitutionGroup[list[i].Name] = n;
            }
            _sb.Append("  </element>\n");
            return string.Empty;
        }

        void AppendEnum(string[] enume)
        {
            for (var j = 0; j < enume.Length; j++)
            {
                _sb.Append($"      <enumeration value='{enume[j]}'/>\n");
            }
        }

        void AppendAttrDecls(string[] atts)
        {
            for (var i = 0; i < atts.Length; i++)
            {
                if (atts[i] == "#ATTRGROUPREF")
                {
                    _sb.Append($"   <attributeGroup ref='{_prefix}:{atts[i + 1]}'/>\n");
                    i++;
                }
                else
                {
                    //# attribute name
                    _sb.Append($"   <attribute name='{atts[i]}'");

                    //# attribute type
                    var enume = new List<string>();
                    i++;
                    if (atts[i] == "(")
                    {
                        //# like `attname ( yes | no ) #REQUIRED`
                        i++;
                        while (atts[i] != ")")
                        {
                            if (atts[i] != "|")
                            {
                                enume.Add(atts[i]);
                            }
                            i++;
                        }
                    }
                    else if (atts[i] == "#DATATYPEREF")
                    {
                        _sb.Append($" type='{_prefix}:{atts[++i]}'");
                    }
                    else if (_alias == 1 &&
                             Regex.IsMatch(atts[i], "$" + alias_ident, RegexOptions.Singleline | RegexOptions.IgnoreCase))
                    {
                        //# alias special
                        _sb.Append($" type='{_aliasDic[atts[i]]}'");
                    }
                    else if (Regex.IsMatch(atts[i], "ID|IDREF|ENTITY|NOTATION|IDREFS|ENTITIES|NMTOKEN|NMTOKENS"))
                    {
                        //# common type for DTD and Schema
                        _sb.Append($" type='{atts[i]}'");
                    }
                    else
                    {
                        //# `attname CDATA #REQUIRED`
                        _sb.Append(" type='string'");
                    }

                    i++;

                    //# #FIXED
                    if (atts[i] == "#FIXED")
                    {
                        i++;
                        _sb.Append($" fixed='{atts[i]}'/>\n");
                    }
                    else
                    {
                        //# minOccurs
                        if (atts[i] == "#REQUIRED")
                        {
                            _sb.Append(" use='required'");
                        }
                        else if (atts[i] == "#IMPLIED")
                        {
                            //sb.Append(" use='optional'");//NOT NEEDED
                        }
                        else
                        {
                            //sb.Append($" use='default' value='{atts[i]}'");
                            _sb.Append($" default=\"{atts[i]}\"");
                        }

                        //# enumerate
                        if (enume.Count <= 0)
                        {
                            _sb.Append("/>\n");
                        }
                        else
                        {
                            _sb.Append(">\n");
                            _sb.Append("    <simpleType>\n");
                            _sb.Append("     <restriction base='string'>\n");
                            AppendEnum(enume.ToArray());
                            _sb.Append("     </restriction>\n");
                            _sb.Append("    </simpleType>\n");
                            _sb.Append("   </attribute>\n");
                        }
                    }
                }
            }
        }

        //# Parse a string into an array of "words".
        //# Words are whitespace-separated sequences of non-whitespace characters,
        //# or quoted strings ("" or ''), with the quotes removed.
        //# HACK: added () stuff for attlist stuff
        //# Parse words for attribute list
        string[] ParseWords(string line)
        {
            line = Regex.Replace(line, @"(\(|\)|\|)", _ => " " + _.Groups[1].Value + " ");
            var words = new List<string>();
            Match res;
            while (!string.IsNullOrEmpty(line))
            {
                if ((res = Regex.Match(line, @"^\s+")).Success)
                {
                    //# Skip whitespace
                }
                else if ((res = Regex.Match(line, "^\"((?:[^\"]|\\\")*)\"")).Success)
                {
                    words.Add(res.Groups[1].Value);
                }
                else if ((res = Regex.Match(line, "^\'((?:[^\']|\\\')*)\'")).Success)
                {
                    words.Add(res.Groups[1].Value);
                }
                else if ((res = Regex.Match(line, @"^\S+")).Success)
                {
                    words.Add(res.Groups[0].Value);
                }
                else
                {
                    throw new Exception("Cannot happen\n");
                }
                var pos = line.IndexOf(res.Groups[0].Value) + res.Groups[0].Value.Length;
                line = line.Substring(pos);
            }

            return words.ToArray();
        }

        Elements[] MakeChildList(string groupName, string[] model)
        {
            var ret = new List<Elements>();
            var brace = new List<int>();
            for (var i = 0; i < model.Length; i++)
            {
                var n = model[i];
                switch (n)
                {
                    case "(":
                        {
                            ret.Add(Elements.Sequence);
                            brace.Add(ret.Count - 1);
                            break;
                        }
                    case ")":
                        {
                            if (i < model.Length - 1)
                            {
                                var lastBraceIndex = brace.Last();
                                if (_occurranceIndicator.ContainsKey(model[i + 1]))
                                {
                                    ret[lastBraceIndex].Occurance = _occurranceIndicator[model[i + 1]];
                                    i++;
                                }
                            }
                            brace.RemoveAt(brace.Count - 1);
                            ret.Add(new Elements(Keys.SequenceEnded));
                            break;
                        }
                    case ",":
                        {
                            ret[brace.Last()] = Elements.Sequence; //"0";
                            break;
                        }
                    case "|":
                        {
                            ret[brace.Last()] = Elements.Choice; // "10";
                            break;
                        }
                    case "#PCDATA":
                        {
                            if (model[i + 1] == "|")
                            {
                                i++;
                            }
                            if (!string.IsNullOrEmpty(groupName))
                            {
                                _mixed[groupName] = 1;
                            }
                            break;
                        }
                    default:
                        {
                            if (_occurranceIndicator.ContainsKey(n))
                            {
                                ret.Last().Occurance = _occurranceIndicator[n];
                                break;
                            }

                            ret.Add(new Elements(n));
                            break;
                        }
                }
            }

            //# "( ( a | b | c )* )" gets mapped to "0 10 a b c 20 20" which will generate
            //# a spurious sequence element. This is not too harmful when this is an
            //# element content model, but with model groups it is incorrect.
            //# In general we need to strip off 0 20 from the ends when it is redundant. 
            //# Redundant means: there is some other group that bounds the whole list. 
            //# Note that it gets a little tricky:
            //# ( (a|b),(c|d) ) gets mapped to "0 10 a b 20 10 c d 20 20". If one
            //# naively chops off the 0 and 20 on the groups that there is a 10 on one
            //# end and a 20 on the other, one loses the bounding sequence, which is 
            //# required in this case.
            //#
            if (ret[0].Name == Keys.SequenceStarted &&
                ret.Last().Name == Keys.SequenceEnded &&
                (ret[1].Type != ElementType.Default)
                )
            {
                //# OK, it is possible that the 0 20 is redundant. Now scan for balance:
                //# All interim 20 between the proposed new start and the proposed new
                //# final one should be at level 1 or above. 
                var depth = 0;
                var redundantParen = 1; //# Assume redundant until proved otherwise
                for (var i = 1; i <= ret.Count - 1; i++)
                {
                    if (ret[i].Name == Keys.SequenceEnded)
                    {
                        depth--;
                        if (i < ret.Count - 1 && depth < 1)
                        {
                            redundantParen = 0;
                            //print STDERR "i=$i,depth=$depth\n";
                        }
                    }
                    else if (ret[i].Type != ElementType.Default)
                    {
                        depth++;
                    }
                } //# for

                if (redundantParen == 1)
                {
                    //print STDERR "Truncating @ret\n";
                    ret.RemoveAt(ret.Count - 1);
                }
            }
            return ret.ToArray();
        }

        void PrintChildList(int numSpaces, Elements[] list)
        {
            var currentTag = new List<string>();
            for (var i = 0; i < list.Length; i++)
            {
                var n = list[i];

                if (n.Type == ElementType.Sequence)
                {
                    if ((_pcdataFlag == 0) && (n.Occurance == DtdOccurance.Default || n.Occurance == DtdOccurance.ZeroOrMore) && i < list.Length - 1 && list[i + 1].Name == Keys.SequenceEnded)
                    {
                        //# The whole list is 0 20 or 1 20; i.e. (#PCDATA) or (#PCDATA)*. 
                        //# Don't generate a sequence child; mixed handles all this.
                    }
                    else
                    {
                        //# my $do_it_flag = 1;
                        if (currentTag.LastOrDefault() == string.Empty && n.Occurance == DtdOccurance.Default)
                        {
                            currentTag.Add(string.Empty);
                            //#                      my $n_1 = $list[$i+1];
                            //#                      if ( $n_1 eq 10 || $n_1 eq 11 || $n_1 eq 12 || $n_1 eq 13 )
                            //#                      {
                            //#                           # do nothing: we have a phantom sequence wrapping a choice
                            //#                           # that we want to not want to appear. OTOH we want a top 
                            //#                           # level sequence in other cases.
                            //#                           $do_it_flag = 0;
                            //#                      }
                        }

                        //#                 if ( $do_it_flag eq 1 )
                        //#  {
                        PrintSpace(numSpaces);
                        numSpaces++;
                        _sb.Append("<sequence");
                        _sb.Append(_occuranceValues[n.Occurance]);
                        _sb.Append(">\n");
                        currentTag.Add("sequence");
                    }
                    //#}
                }
                else if (n.Type == ElementType.Choice)
                {
                    PrintSpace(numSpaces);
                    numSpaces++;
                    _sb.Append("<choice");
                    _sb.Append(_occuranceValues[n.Occurance]);
                    _sb.Append(">\n");
                    currentTag.Add("choice");
                }
                else if (n.Name == Keys.SequenceEnded)
                {
                    var tag = currentTag.LastOrDefault();
                    if (!string.IsNullOrEmpty(tag))
                    {
                        currentTag.RemoveAt(currentTag.Count - 1);
                        numSpaces--;
                        PrintSpace(numSpaces);
                        _sb.Append($"</{tag}>\n");
                    }
                }
                else
                {
                    PrintSpace(numSpaces);

                    if (n.Name == "#MODELGROUPREF")
                    {
                        _sb.Append($"<group{_occuranceValues[n.Occurance]} ref='{_prefix}:{list[++i]}'/>\n");
                    }
                    else if (n.Name == "#SUBSTGROUPREF")
                    {
                        _sb.Append($"<element{_occuranceValues[n.Occurance]} ref='{_prefix}:{list[++i]}'/>\n");
                    }
                    else
                    {
                        _sb.Append($"<element{_occuranceValues[n.Occurance]} ref='{_prefix}:{n}'/>\n");
                    }

                    //if (currentTag[currentTag.Count - 1] != "choice")
                    //{
                    //    if (i < list.Length - 1)
                    //    {
                    //        if (_occursCharTypes2.ContainsKey(list[i + 1].Name))
                    //        {
                    //            _sb.Append(occuranceValues[_occursCharTypes2[list[i + 1].Name]]);
                    //            i++;
                    //        }
                    //    }
                    //}
                    //_sb.Append("");
                }
            }
        }

        void PrintSpace(int num)
        {
            for (var i = 0; i < num; i++)
            {
                _sb.Append(" ");
            }
        }

        //# loop over elements, writing XML schema
        void BuildXmlSchemaContent()
        {
            foreach (var e in _elements)
            {
                var elementModel = _modelContent[e];
                string[] elementAttributes;
                _attributes.TryGetValue(e, out elementAttributes);

                var isSimple = (_pcdataFlag == 1) && elementModel.Length > 1 && elementModel[1] == "#PCDATA" && ((elementModel.Length == 3) || ((elementModel.Length == 4) && (elementModel[3] == "*")));
                var substGroupStr = string.Empty;
                if (_substitutionGroup.ContainsKey(e))
                {
                    substGroupStr = $" substitutionGroup='{_substitutionGroup[e]}'";
                }

                //# print rule for element $e
                if (isSimple && elementAttributes == null)
                {
                    //# Assume (#PCDATA) is string
                    _sb.Append($"\n <element name='{e}' type='{_pcdataSimpletype}'{substGroupStr}>\n");
                }
                else
                {
                    _sb.Append($"\n <element name='{e}'{substGroupStr}>\n");
                }

                if (isSimple)
                {
                    //# Assume (#PCDATA) is string
                    if (elementAttributes != null)
                    {
                        _sb.Append("  <complexType>\n");
                        _sb.Append("  <simpleContent>\n");
                        _sb.Append("  <extension base='string'>\n");
                    }
                }
                else
                {
                    //# print rule for $e's content model
                    _sb.Append("  <complexType");
                    if (elementModel[0] == "EMPTY")
                    {
                        _sb.Append(elementAttributes == null ? "/>\n" : ">\n");
                    }
                    else if (elementModel[0] == "ANY")
                    {
                        _sb.Append(">\n");
                        _sb.Append("   <sequence>\n");
                        _sb.Append("   <any namespace='" + Constants.TempNameSpace + "'/>\n");
                        _sb.Append("   </sequence>\n");
                    }
                    else
                    {
                        if (IsMixed(elementModel))
                        {
                            _sb.Append(" mixed='true'>\n");
                        }
                        else
                        {
                            _sb.Append(">\n");
                        }

                        var list = MakeChildList(string.Empty, elementModel);
                        PrintChildList(3, list);
                    }
                }

                //# print rule for $e's attributes
                if (elementAttributes == null)
                {
                    //# nothing
                }
                else
                {
                    AppendAttrDecls(elementAttributes);
                    if (isSimple)
                    {
                        _sb.Append("   </extension>\n");
                        _sb.Append("   </simpleContent>\n");
                    }
                }

                if (elementAttributes == null && isSimple)
                {
                    //# Do nothing
                }
                else if (elementAttributes != null || elementModel[0] != "EMPTY")
                {
                    _sb.Append("  </complexType>\n");
                }

                _sb.Append(" </element>\n");
            }
            _sb.Append("</schema>\n");
        }

        bool IsMixed(string[] model)
        {
            var isSimple = (_pcdataFlag == 1) && model.Length > 1 && model[1] == "#PCDATA" && ((model.Length == 3) || ((model.Length == 4) && (model[3] == "*")));
            if (isSimple)
                return false;
            for (var i = 0; i < model.Length; i++)
            {
                if (model[i] == "#PCDATA" ||
                    (model[i] == "#MODELGROUPREF" && i < model.Length - 1 && _mixed.ContainsKey(model[i + 1])) ||
                    (model[i] == "#SUBSTGROUPREF" && i < model.Length - 1 && _mixed.ContainsKey(model[i + 1])))
                {
                    return true;
                }
            }
            return false;
        }

        abstract class Keys
        {
            public const string SequenceStarted = "__Sequence_Started__"; //0
            public const string SequenceEnded = "__Sequence_Ended__"; //20
            public const string ChoiceStarted = "__Choice_Started__"; //10
        }

        abstract class Values
        {
            public const string Empty = "";
            public const string ZeroOrMore = " minOccurs='0' maxOccurs='unbounded'"; //1
            public const string OneOrMore = " maxOccurs='unbounded'"; //2
            public const string Optional = " minOccurs='0' maxOccurs='1'"; //3
        }

        enum DtdOccurance
        {
            Default,
            ZeroOrMore,
            OneOrMore,
            Optional
        }

        enum ElementType
        {
            Default,
            Sequence,
            Choice
        }

        class Elements
        {
            public Elements(string name)
            {
                Name = name;
                Occurance = DtdOccurance.Default;
                Type = ElementType.Default;
            }

            public string Name { get; }
            public DtdOccurance Occurance { get; set; }
            public ElementType Type { get; set; }

            public static Elements Sequence => new Elements(Keys.SequenceStarted) { Type = ElementType.Sequence };
            public static Elements Choice => new Elements(Keys.ChoiceStarted) { Type = ElementType.Choice };

            public override string ToString()
            {
                return Name;
            }
        }
    }
}