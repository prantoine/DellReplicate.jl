```@meta
CurrentModule = DellReplicate
```
# Functions for Table 1.

This page contains the specific functions used to create `Table 1`. Some functions which are common to multiple tables/figures may not be present.

## Table 1
```@raw html
<table>
  <thead>
    <tr class = "header">
      <th style = "text-align: right;">Statistic</th>
      <th style = "text-align: right;">Quarter</th>
      <th style = "text-align: right;">Half</th>
      <th style = "text-align: right;">ThreeQuarter</th>
      <th style = "text-align: right;">One</th>
      <th style = "text-align: right;">One_and_quarter</th>
      <th style = "text-align: right;">One_and_half</th>
    </tr>
    <tr class = "subheader headerLastRow">
      <th style = "text-align: right;">String</th>
      <th style = "text-align: right;">Float64</th>
      <th style = "text-align: right;">Float64</th>
      <th style = "text-align: right;">Float64</th>
      <th style = "text-align: right;">Float64</th>
      <th style = "text-align: right;">Float64</th>
      <th style = "text-align: right;">Float64</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style = "text-align: right;">Raw Data</td>
      <td style = "text-align: right;">0.573</td>
      <td style = "text-align: right;">0.299</td>
      <td style = "text-align: right;">0.144</td>
      <td style = "text-align: right;">0.064</td>
      <td style = "text-align: right;">0.028</td>
      <td style = "text-align: right;">0.011</td>
    </tr>
    <tr>
      <td style = "text-align: right;">Without year FE</td>
      <td style = "text-align: right;">0.511</td>
      <td style = "text-align: right;">0.215</td>
      <td style = "text-align: right;">0.085</td>
      <td style = "text-align: right;">0.032</td>
      <td style = "text-align: right;">0.013</td>
      <td style = "text-align: right;">0.005</td>
    </tr>
  </tbody>
</table>
```
## Table 2

```@raw html
<table>
  <thead>
    <tr class = "header">
      <th style = "text-align: right;">Statistic</th>
      <th style = "text-align: right;">One</th>
      <th style = "text-align: right;">Two</th>
      <th style = "text-align: right;">Three</th>
      <th style = "text-align: right;">Four</th>
      <th style = "text-align: right;">Five</th>
      <th style = "text-align: right;">Six</th>
    </tr>
    <tr class = "subheader headerLastRow">
      <th style = "text-align: right;">String</th>
      <th style = "text-align: right;">Float64</th>
      <th style = "text-align: right;">Float64</th>
      <th style = "text-align: right;">Float64</th>
      <th style = "text-align: right;">Float64</th>
      <th style = "text-align: right;">Float64</th>
      <th style = "text-align: right;">Float64</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style = "text-align: right;">Raw Data</td>
      <td style = "text-align: right;">0.48</td>
      <td style = "text-align: right;">0.229</td>
      <td style = "text-align: right;">0.121</td>
      <td style = "text-align: right;">0.07</td>
      <td style = "text-align: right;">0.042</td>
      <td style = "text-align: right;">0.027</td>
    </tr>
    <tr>
      <td style = "text-align: right;">Without year FE</td>
      <td style = "text-align: right;">0.494</td>
      <td style = "text-align: right;">0.221</td>
      <td style = "text-align: right;">0.113</td>
      <td style = "text-align: right;">0.062</td>
      <td style = "text-align: right;">0.038</td>
      <td style = "text-align: right;">0.024</td>
    </tr>
  </tbody>
</table>
```

```@docs
make_table1
```