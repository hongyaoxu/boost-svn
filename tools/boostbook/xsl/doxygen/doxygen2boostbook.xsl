<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">
  <xsl:import href="../lookup.xsl"/>

  <!-- Set this parameter to a space-separated list of headers that
       will be included in the output (all others are ignored). If this
       parameter is omitted or left as the empty string, all headers will
       be output. -->
  <xsl:param name="boost.doxygen.headers" select="''"/>

  <!-- Prefix all of the headers output with this string -->
  <xsl:param name="boost.doxygen.header.prefix" select="''"/>

  <xsl:output method="xml" indent="yes" standalone="yes"/>

  <xsl:key name="compounds-by-kind" match="compounddef" use="@kind"/>
  <xsl:key name="compounds-by-id" match="compounddef" use="@id"/>
  <xsl:key name="inner-classes" match="compounddef[not(attribute::kind='namespace')]/innerclass" use="@refid"/>

  <xsl:strip-space elements="briefdescription detaileddescription"/>

  <xsl:template match="/">
    <xsl:apply-templates select="doxygen"/>
  </xsl:template>

  <xsl:template match="doxygen">
    <library-reference>
      <xsl:apply-templates select="key('compounds-by-kind', 'file')"/>
    </library-reference>
  </xsl:template>

  <xsl:template match="compounddef">
    <!-- The set of innernamespace nodes that limits our search -->
    <xsl:param name="with-namespace-refs"/>
    <xsl:param name="in-file"/>

    <xsl:choose>
      <xsl:when test="@kind='file'">
        <xsl:call-template name="file"/>
      </xsl:when>
      <xsl:when test="@kind='namespace'">
        <xsl:call-template name="namespace">
          <xsl:with-param name="with-namespace-refs" 
            select="$with-namespace-refs"/>
          <xsl:with-param name="in-file" select="$in-file"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="@kind='class'">
        <xsl:call-template name="class">
          <xsl:with-param name="class-key" select="'class'"/>
          <xsl:with-param name="in-file" select="$in-file"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="@kind='struct'">
        <xsl:call-template name="class">
          <xsl:with-param name="class-key" select="'struct'"/>
          <xsl:with-param name="in-file" select="$in-file"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="@kind='union'">
        <xsl:call-template name="class">
          <xsl:with-param name="class-key" select="'union'"/>
          <xsl:with-param name="in-file" select="$in-file"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>
Cannot handle compounddef with kind=<xsl:value-of select="@kind"/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="namespace">
    <!-- The set of innernamespace nodes that limits our search -->
    <xsl:param name="with-namespace-refs"/>
    <xsl:param name="in-file"/>

    <xsl:variable name="fullname" select="string(compoundname)"/>

    <xsl:if test="$with-namespace-refs[string(text())=$fullname]">
      <!-- Namespace without the prefix -->
      <xsl:variable name="rest">
        <xsl:call-template name="strip-qualifiers">
          <xsl:with-param name="name" select="compoundname"/>
        </xsl:call-template>
      </xsl:variable>
      
      <!-- Grab only the namespace name, not any further nested namespaces -->
      <xsl:variable name="name">
        <xsl:choose>
          <xsl:when 
            test="contains($rest, '::')">
            <xsl:value-of select="substring-before($rest, '::')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$rest"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <namespace>
        <xsl:attribute name="name">
          <xsl:value-of select="$name"/>
        </xsl:attribute>
        
        <xsl:apply-templates>
          <xsl:with-param name="with-namespace-refs" 
            select="$with-namespace-refs"/>
          <xsl:with-param name="in-file" select="$in-file"/>
        </xsl:apply-templates>
      </namespace>
    </xsl:if>
  </xsl:template>

  <xsl:template name="class">
    <xsl:param name="class-key"/>
    <xsl:param name="in-file"/>
    <xsl:param name="with-namespace-refs"/>

    <xsl:if test="contains(string(location/attribute::file), 
                           concat('/', $in-file)) and
                  not (contains(string(compoundname), '&lt;')) and
                  not (key('inner-classes', @id))">
      <!-- The short name of this class -->
      <xsl:variable name="name">
        <xsl:call-template name="strip-qualifiers">
          <xsl:with-param name="name" select="compoundname"/>
        </xsl:call-template>
      </xsl:variable>
      
      <xsl:element name="{$class-key}">
        <xsl:attribute name="name">
          <xsl:value-of select="$name"/>
        </xsl:attribute>
        
        <xsl:apply-templates select="templateparamlist" mode="template"/>
        <xsl:apply-templates select="basecompoundref" mode="inherit"/>

        <xsl:apply-templates select="briefdescription" mode="passthrough"/>
        <xsl:apply-templates select="detaileddescription" mode="passthrough"/>
        <xsl:apply-templates/>
      </xsl:element>
    </xsl:if>
  </xsl:template>

  <xsl:template name="enum">
    <xsl:variable name="name">
      <xsl:call-template name="strip-qualifiers">
        <xsl:with-param name="name" select="name"/>
      </xsl:call-template>
    </xsl:variable>

    <enum>
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>

      <xsl:apply-templates select="enumvalue"/>

      <xsl:apply-templates select="briefdescription" mode="passthrough"/>
      <xsl:apply-templates select="detaileddescription" mode="passthrough"/>
    </enum>
  </xsl:template>

  <xsl:template match="enumvalue">
    <enumvalue>
      <xsl:attribute name="name">
        <xsl:value-of select="name"/>
      </xsl:attribute>

      <xsl:if test="initializer">
        <default>
          <xsl:apply-templates select="initializer" mode="passthrough"/>
        </default>
      </xsl:if>
    </enumvalue>
  </xsl:template>

  <xsl:template name="doxygen.include.header.rec">
    <xsl:param name="name"/>
    <xsl:param name="header-list" select="$boost.doxygen.headers"/>

    <xsl:choose>
      <xsl:when test="contains($header-list, ' ')">
        <xsl:variable name="header" 
          select="substring-before($header-list, ' ')"/>
        <xsl:variable name="rest" select="substring-after($header-list, ' ')"/>

        <xsl:choose>
          <xsl:when test="$name=$header">
            <xsl:text>yes</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="doxygen.include.header.rec">
              <xsl:with-param name="name" select="$name"/>
              <xsl:with-param name="header-list" select="$rest"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$name=$header-list">
        <xsl:text>yes</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="doxygen.include.header">
    <xsl:param name="name"/>
    
    <xsl:if test="$boost.doxygen.headers=''">
      <xsl:text>yes</xsl:text>
    </xsl:if>
    <xsl:if test="not($boost.doxygen.headers='')">
      <xsl:call-template name="doxygen.include.header.rec">
        <xsl:with-param name="name" select="$name"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="file">
    <xsl:variable name="include-header">
      <xsl:call-template name="doxygen.include.header">
        <xsl:with-param name="name" select="string(compoundname)"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:if test="$include-header='yes'">
      <header>
        <xsl:attribute name="name">
          <xsl:value-of select="concat($boost.doxygen.header.prefix, 
                                       string(compoundname))"/>
        </xsl:attribute>
        
        <xsl:apply-templates select="briefdescription" mode="passthrough"/>
        <xsl:apply-templates select="detaileddescription" mode="passthrough"/>
        
        <xsl:apply-templates mode="toplevel">
          <xsl:with-param name="with-namespace-refs"
            select="innernamespace"/>
          <xsl:with-param name="in-file" select="string(compoundname)"/>
        </xsl:apply-templates>
      </header>
    </xsl:if>
  </xsl:template>

  <xsl:template match="innernamespace">
    <xsl:param name="with-namespace-refs"/>
    <xsl:param name="in-file"/>

    <xsl:apply-templates select="key('compounds-by-id', @refid)">
      <xsl:with-param name="with-namespace-refs"
        select="$with-namespace-refs"/>
      <xsl:with-param name="in-file" select="$in-file"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="innernamespace" mode="toplevel">
    <!-- The set of innernamespace nodes that limits our search -->
    <xsl:param name="with-namespace-refs"/>
    <xsl:param name="in-file"/>

    <!-- The full name of the namespace we are referring to -->
    <xsl:variable name="fullname" 
      select="string(key('compounds-by-id', @refid)/compoundname)"/>

    <!-- Only pass on top-level namespaces -->
    <xsl:if test="not(contains($fullname, '::'))">
      <xsl:apply-templates select="key('compounds-by-id', @refid)">
        <xsl:with-param name="with-namespace-refs" 
          select="$with-namespace-refs"/>
        <xsl:with-param name="in-file" select="$in-file"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>

  <xsl:template match="innerclass">
    <xsl:param name="with-namespace-refs"/>
    <xsl:param name="in-file"/>

    <xsl:apply-templates select="key('compounds-by-id', @refid)">
      <xsl:with-param name="with-namespace-refs" 
        select="$with-namespace-refs"/>
      <xsl:with-param name="in-file" select="$in-file"/>
    </xsl:apply-templates>
  </xsl:template>

  <!-- Classes -->
  <xsl:template match="templateparamlist" mode="template">
    <template>
      <xsl:apply-templates mode="template"/>
    </template>
  </xsl:template>

  <xsl:template match="param" mode="template">
    <xsl:choose>
      <xsl:when test="string(type)='class' or string(type)='typename'">
        <template-type-parameter>
          <xsl:attribute name="name">
            <xsl:value-of select="string(declname)"/>
          </xsl:attribute>
          <xsl:if test="defval">
            <default>
              <xsl:apply-templates select="defval/*|defval/text()" 
                mode="passthrough"/>
            </default>
          </xsl:if>
        </template-type-parameter>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>
Cannot handle template parameter with type <xsl:value-of select="string(type)"/>          
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="templateparamlist"/>

  <!-- Inheritance -->
  <xsl:template match="basecompoundref" mode="inherit">
    <inherit>
      <!-- Access specifier for inheritance -->
      <xsl:attribute name="access">
        <xsl:value-of select="@prot"/>
      </xsl:attribute>
      <!-- TBD: virtual vs. non-virtual inheritance -->

      <xsl:apply-templates mode="passthrough"/>
    </inherit>
  </xsl:template>

  <xsl:template match="basecompoundref"/>

  <!-- Skip over sections: they aren't very useful at all -->
  <xsl:template match="sectiondef">
    <xsl:param name="in-file" select="''"/>

    <xsl:choose>
      <xsl:when test="@kind='public-static-func'">
        <!-- TBD: pass on the fact that these are static functions -->
        <method-group name="public static functions">
          <xsl:apply-templates>
            <xsl:with-param name="in-section" select="true()"/>
          </xsl:apply-templates>
        </method-group>
      </xsl:when>
      <xsl:when test="@kind='protected-static-func'">
        <!-- TBD: pass on the fact that these are static functions -->
        <method-group name="protected static functions">
          <xsl:apply-templates>
            <xsl:with-param name="in-section" select="true()"/>
          </xsl:apply-templates>
        </method-group>
      </xsl:when>
      <xsl:when test="@kind='private-static-func'">
        <!-- TBD: pass on the fact that these are static functions -->
        <method-group name="private static functions">
          <xsl:apply-templates>
            <xsl:with-param name="in-section" select="true()"/>
          </xsl:apply-templates>
        </method-group>
      </xsl:when>
      <xsl:when test="@kind='public-func'">
        <method-group name="public member functions">
          <xsl:apply-templates>
            <xsl:with-param name="in-section" select="true()"/>
          </xsl:apply-templates>
        </method-group>
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:when test="@kind='protected-func'">
        <method-group name="protected member functions">
          <xsl:apply-templates>
            <xsl:with-param name="in-section" select="true()"/>
          </xsl:apply-templates>
        </method-group>
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:when test="@kind='private-func'">
        <method-group name="private member functions">
          <xsl:apply-templates>
            <xsl:with-param name="in-section" select="true()"/>
          </xsl:apply-templates>
        </method-group>
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:when test="@kind='public-type'">
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:when test="@kind='func'">
        <xsl:apply-templates>
          <xsl:with-param name="in-file" select="$in-file"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="@kind='typedef'">
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:when test="@kind='enum'">
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>
Cannot handle sectiondef with kind=<xsl:value-of select="@kind"/>      
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Handle member definitions -->
  <xsl:template match="memberdef">
    <!-- True when we're inside a section -->
    <xsl:param name="in-section" select="false()"/>
    <xsl:param name="in-file" select="''"/>

    <xsl:choose>
      <xsl:when test="@kind='typedef'">
        <xsl:call-template name="typedef"/>
      </xsl:when>
      <xsl:when test="@kind='function'">
        <xsl:choose>
          <xsl:when test="ancestor::compounddef/attribute::kind='namespace'">
            <xsl:call-template name="function">
              <xsl:with-param name="in-file" select="$in-file"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <!-- We are in a class -->
            <!-- The name of the class we are in -->
            <xsl:variable name="in-class">
              <xsl:call-template name="strip-qualifiers">
                <xsl:with-param name="name" 
                  select="string(ancestor::compounddef/compoundname/text())"/>
              </xsl:call-template>
            </xsl:variable>
            
            <xsl:choose>
              <xsl:when test="string(name/text())=$in-class">
                <xsl:if test="not ($in-section)">
                  <xsl:call-template name="constructor"/>
                </xsl:if>
              </xsl:when>
              <xsl:when test="string(name/text())=concat('~',$in-class)">
                <xsl:if test="not ($in-section)">
                  <xsl:call-template name="destructor"/>
                </xsl:if>
              </xsl:when>
              <xsl:when test="string(name/text())='operator='">
                <xsl:if test="not ($in-section)">
                  <xsl:call-template name="copy-assignment"/>
                </xsl:if>
              </xsl:when>
              <xsl:otherwise>
                <xsl:if test="$in-section">
                  <xsl:call-template name="method"/>
                </xsl:if>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="@kind='enum'">
        <xsl:call-template name="enum"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>
Cannot handle memberdef element with kind=<xsl:value-of select="@kind"/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Display typedefs -->
  <xsl:template name="typedef">
    <!-- TBD: Handle public/protected/private -->
    <typedef>
      <!-- Name of the type -->
      <xsl:attribute name="name">
        <xsl:value-of select="name/text()"/>
      </xsl:attribute>
      
      <xsl:apply-templates select="briefdescription" mode="passthrough"/>
      <xsl:apply-templates select="detaileddescription" mode="passthrough"/>
      
      <type>
        <xsl:apply-templates select="type/text()|type/*"
          mode="passthrough"/>
      </type>
    </typedef>
  </xsl:template>

  <!-- Handle function parameters -->
  <xsl:template match="param" mode="function">
    <parameter>
      <!-- Parameter name -->
      <xsl:attribute name="name">
        <xsl:value-of select="declname/text()"/>
      </xsl:attribute>

      <!-- Parameter type -->
      <paramtype>
        <xsl:apply-templates select="type/*|type/text()" mode="passthrough"/>
      </paramtype>

      <!-- TBD: handling of parameter descriptions -->
      <xsl:if test="defval">
        <default>
          <xsl:apply-templates select="defval/*|defval/text()" 
            mode="passthrough"/>
        </default>
      </xsl:if>
    </parameter>
  </xsl:template>

  <!-- Handle function children -->
  <xsl:template name="function.children">
    <!-- Emit template header -->
    <xsl:apply-templates select="templateparamlist" mode="template"/>

    <!-- Emit function parameters -->
    <xsl:apply-templates select="param" mode="function"/>
    
    <!-- The description -->
    <xsl:apply-templates select="briefdescription" mode="passthrough"/>
    <xsl:apply-templates select="detaileddescription" mode="passthrough"/>
      
    <xsl:apply-templates 
      select="detaileddescription/para/simplesect[@kind='post']"
      mode="function-clauses"/>
    <xsl:apply-templates 
      select="detaileddescription/para/simplesect[@kind='return']"
      mode="function-clauses"/>
    <xsl:if test="detaileddescription/para/parameterlist[@kind='exception']">
      <throws>
        <xsl:apply-templates 
          select="detaileddescription/para/parameterlist[@kind='exception']"
          mode="function-clauses"/>
      </throws>
    </xsl:if>
  </xsl:template>

  <!-- Handle free functions -->
  <xsl:template name="function">
    <xsl:param name="in-file" select="''"/>

    <xsl:if test="contains(string(location/attribute::file), $in-file)">
      <function>
        <xsl:attribute name="name">
          <xsl:value-of select="name/text()"/>
        </xsl:attribute>
        
        <!-- Return type -->
        <type>
          <xsl:value-of select="type"/>
        </type>

        <xsl:call-template name="function.children"/>
      </function>
    </xsl:if>
  </xsl:template>

  <!-- Handle constructors -->
  <xsl:template name="constructor">
    <constructor>
      <xsl:call-template name="function.children"/>
    </constructor>
  </xsl:template>

  <!-- Handle Destructors -->
  <xsl:template name="destructor">
    <destructor>
      <xsl:call-template name="function.children"/>
    </destructor>
  </xsl:template>

  <!-- Handle Copy Assignment -->
  <xsl:template name="copy-assignment">
    <copy-assignment>
      <xsl:call-template name="function.children"/>
    </copy-assignment>
  </xsl:template>

  <!-- Handle methods -->
  <xsl:template name="method">
    <method>
      <xsl:attribute name="name">
        <xsl:value-of select="name/text()"/>
      </xsl:attribute>

      <!-- TBD: virtual and static functions -->

      <!-- CV Qualifiers -->
      <xsl:if test="not (@const='no' and @volatile='no')">
        <xsl:attribute name="cv">
          <xsl:if test="@const='yes'">
            <xsl:text>const</xsl:text>
          </xsl:if>
          <xsl:if test="@volatile='yes'">
            <xsl:if test="@const='yes'">
              <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:text>volatile</xsl:text>
          </xsl:if>
        </xsl:attribute>
      </xsl:if>

      <!-- Return type -->
      <type>
        <xsl:value-of select="type"/>
      </type>

      <xsl:call-template name="function.children"/>
    </method>
  </xsl:template>

  <!-- Things we ignore directly -->
  <xsl:template match="compoundname" mode="toplevel"/>
  <xsl:template match="includes|includedby|incdepgraph|invincdepgraph" mode="toplevel"/>
  <xsl:template match="programlisting" mode="toplevel"/>
  <xsl:template match="text()" mode="toplevel"/>

  <xsl:template match="text()"/>

  <!-- Passthrough of text -->
  <xsl:template match="text()" mode="passthrough">
    <xsl:value-of select="."/>
  </xsl:template>
  <xsl:template match="para" mode="passthrough">
    <para>
      <xsl:apply-templates mode="passthrough"/>
    </para>
  </xsl:template>

  <xsl:template match="para/simplesect" mode="passthrough">
    <xsl:if test="not (@kind='return') and 
                  not (@kind='post')">
      <xsl:apply-templates mode="passthrough"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="parameterlist" mode="passthrough"/>

  <xsl:template match="bold" mode="passthrough">
    <emphasis role="bold">
      <xsl:apply-templates mode="passthrough"/>
    </emphasis>
  </xsl:template>

  <xsl:template match="briefdescription" mode="passthrough">
    <xsl:if test="text()|*">
      <purpose>
        <xsl:apply-templates mode="passthrough"/>
      </purpose>
    </xsl:if>
  </xsl:template>

  <xsl:template match="detaileddescription" mode="passthrough">
    <xsl:if test="text()|*">
      <description>
        <xsl:apply-templates mode="passthrough"/>
      </description>
    </xsl:if>
  </xsl:template>

  <!-- Handle function clauses -->
  <xsl:template match="simplesect" mode="function-clauses">
    <xsl:if test="@kind='return'">
      <returns>
        <xsl:apply-templates mode="passthrough"/>
      </returns>
    </xsl:if>
    <xsl:if test="@kind='post'">
      <postconditions>
        <xsl:apply-templates mode="passthrough"/>
      </postconditions>
    </xsl:if>
  </xsl:template>

  <xsl:template match="parameterlist" mode="function-clauses">
    <xsl:if test="@kind='exception'">
      <simpara>
        <classname><xsl:value-of select="parametername/text()"/></classname>
        <xsl:text> </xsl:text>
        <xsl:apply-templates 
          select="parameterdescription/para/text()|parameterdescription/para/*"
          mode="passthrough"/>
      </simpara>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
