```@meta
CurrentModule = DellReplicate
```

# Functions for Table 2.

The main function for `Table 2` is `make_table2` which calls various functions a shown below. 

<table>
  <thead>
    <tr class = "header">
      <th style = "text-align: right;">Dependent variable: annual GDP growth rate</th>
      <th style = "text-align: right;">Model 1</th>
      <th style = "text-align: right;">Model 2</th>
      <th style = "text-align: right;">Model 3</th>
      <th style = "text-align: right;">Model 4</th>
      <th style = "text-align: right;">Model 5</th>
    </tr> 
  </thead>
  <tbody>
    <tr>
      <td style = "text-align: right;">Temperature</td>
      <td style = "text-align: right;">-0.325414</td>
      <td style = "text-align: right;">0.260944</td>
      <td style = "text-align: right;">0.262417</td>
      <td style = "text-align: right;">0.171924</td>
      <td style = "text-align: right;">0.563024</td>
    </tr>
    <tr>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;">(0.2667381063964909)</td>
      <td style = "text-align: right;">(0.292172378732773)</td>
      <td style = "text-align: right;">(0.29127925123569204)</td>
      <td style = "text-align: right;">(0.27461688629574804)</td>
      <td style = "text-align: right;">(0.29776243180916123)</td>
    </tr>
    <tr>
      <td style = "text-align: right;">Poor country dummy</td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;">-1.65515</td>
      <td style = "text-align: right;">-1.60954</td>
      <td style = "text-align: right;">-1.64475</td>
      <td style = "text-align: right;">-1.79081</td>
    </tr>
    <tr>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;">(0.4566307366223894)</td>
      <td style = "text-align: right;">(0.4554073052767715)</td>
      <td style = "text-align: right;">(0.45389741776568265)</td>
      <td style = "text-align: right;">(0.43387893311917186)</td>
    </tr>
    <tr>
      <td style = "text-align: right;">Hot country dummy</td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;">0.2369</td>
      <td style = "text-align: right;"></td>
    </tr>
    <tr>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;">(0.5351042496329304)</td>
      <td style = "text-align: right;"></td>
    </tr>
    <tr>
      <td style = "text-align: right;">Agricultural country dummy</td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;">-0.379312</td>
    </tr>
    <tr>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;">(0.3895778806537779)</td>
    </tr>
    <tr>
      <td style = "text-align: right;">Precipitation</td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;">-0.0830812</td>
      <td style = "text-align: right;">-0.228171</td>
      <td style = "text-align: right;">-0.0984184</td>
    </tr>
    <tr>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;">(0.04264245661412808)</td>
      <td style = "text-align: right;">(0.062045675612721986)</td>
      <td style = "text-align: right;">(0.04449462158369184)</td>
    </tr>
    <tr>
      <td style = "text-align: right;">Poor country dummy</td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;">0.152895</td>
      <td style = "text-align: right;">0.160498</td>
      <td style = "text-align: right;">0.153419</td>
    </tr>
    <tr>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;">(0.06711216733230993)</td>
      <td style = "text-align: right;">(0.06287833488955635)</td>
      <td style = "text-align: right;">(0.07336304702910652)</td>
    </tr>
    <tr>
      <td style = "text-align: right;">Hot country dummy</td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;">0.184694</td>
      <td style = "text-align: right;"></td>
    </tr>
    <tr>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;">(0.06567424550564989)</td>
      <td style = "text-align: right;"></td>
    </tr>
    <tr>
      <td style = "text-align: right;">Agricultural country dummy</td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;">-0.00803258</td>
    </tr>
    <tr>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;"></td>
      <td style = "text-align: right;">(0.06841961679884542)</td>
    </tr>
  </tbody>
</table>        
Standard errors are in parentheses.
<br /><br />

```@docs
make_table2
qr_method
create_cluster
two_way_clustered_sterrs
check_coeffs_table2
```